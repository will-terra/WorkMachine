# AI results of a posting. Nothing here calls the model in bulk or on page load: generation
# only starts on a click.
class AiArtifactsController < ApplicationController
  before_action :set_job_posting, only: %i[ create estimate ]

  def create
    return redirect_to(job_posting_path(@job_posting, anchor: "ia"), alert: "Coloque a chave do OpenRouter em Ajustes para usar a IA.") unless Ai::Client.configured?

    kind = params.require(:kind).presence_in(AiArtifact.kinds.keys) or return head(:unprocessable_content)
    language = params[:language].presence_in(%w[pt en]) || "pt"
    artifact = @job_posting.ai_artifacts.create!(kind:, language:, model: Ai::Client.model)
    GenerateAiArtifactJob.perform_later(artifact)

    redirect_to job_posting_path(@job_posting, anchor: "ia"), notice: "#{artifact.human_enum(:kind)} em andamento. O resultado aparece aqui em alguns segundos."
  end

  # Polled by the pending artifact's Turbo Frame.
  def show
    @ai_artifact = AiArtifact.find(params[:id])
    render partial: "ai_artifacts/ai_artifact", locals: { ai_artifact: @ai_artifact }
  end

  def destroy
    artifact = AiArtifact.find(params[:id])
    artifact.destroy!
    redirect_to job_posting_path(artifact.job_posting, anchor: "ia"), notice: "Resultado apagado.", status: :see_other
  end

  # Lazy Turbo Frame with the cost per click: tokens estimated from the prompt size and
  # prices from OpenRouter's model list. No AI call is made here.
  def estimate
    if Ai::Client.configured?
      prices = Ai::Pricing.for(Ai::Client.model)
      @estimates = Ai::Pricing::EXPECTED_OUTPUT_TOKENS.keys.index_with do |kind|
        Ai::Pricing.estimate(kind, Ai::Pricing.estimate_tokens(Ai::Client.request_text(kind, @job_posting)), prices)
      end
    end
    render layout: false
  end

  private
    def set_job_posting
      @job_posting = JobPosting.find(params[:job_posting_id])
    end
end
