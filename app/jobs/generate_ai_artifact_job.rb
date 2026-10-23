# Generates one AI result (fit analysis, CV summary, recruiter message or interview preparation) in the background.
class GenerateAiArtifactJob < ApplicationJob
  queue_as :default

  def perform(artifact, client: Ai::Client.new)
    return unless artifact.status_pending?

    options = { language: artifact.language || "pt" }
    options[:application] = artifact.job_application if artifact.job_application
    result = client.generate(artifact.kind, artifact.job_posting, **options)
    attributes = {
      model: result.model.to_s,
      input_tokens: result.input_tokens,
      output_tokens: result.output_tokens,
      cache_write_tokens: result.cache_write_tokens,
      cache_read_tokens: result.cache_read_tokens,
      cost_usd: result.cost
    }

    if result.refused?
      artifact.update!(attributes.merge(status: "failed", error_message: I18n.t("ai.errors.refused")))
    else
      note = "\n\n#{I18n.t("ai.errors.truncated")}" if result.truncated?
      artifact.update!(attributes.merge(status: "completed", content: "#{result.text}#{note}"))
    end
  rescue Ai::Client::Error => e
    artifact.update!(status: "failed", error_message: Ai::Client.explain(e))
  rescue SocketError, SystemCallError, Timeout::Error => e
    artifact.update!(status: "failed", error_message: I18n.t("ai.errors.offline", error: e.class))
  end
end
