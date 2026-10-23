# AI results of a posting, and the interview preparation of an application. Nothing here calls the
# model in bulk or on page load: generation only starts on a click.
class AiArtifactsController < ApplicationController
  before_action :set_parent, only: %i[ create estimate ]

  def create
    return redirect_to(parent_path, alert: t("flash.ai.no_key")) unless Ai::Client.configured?

    kind = params.require(:kind).presence_in(allowed_kinds) or return head(:unprocessable_content)
    language = kind == "interview_prep" ? Ai::Prompt.interface_key : (params[:language].presence_in(%w[pt en]) || "pt")
    artifact = AiArtifact.create!(kind:, language:, model: Ai::Client.model, job_posting: @job_posting, job_application: @job_application)
    GenerateAiArtifactJob.perform_later(artifact)

    redirect_to parent_path, notice: t("flash.ai.started", kind: artifact.human_enum(:kind))
  end

  # Polled by the pending artifact's Turbo Frame.
  def show
    @ai_artifact = AiArtifact.find(params[:id])
    render partial: "ai_artifacts/ai_artifact", locals: { ai_artifact: @ai_artifact }
  end

  def destroy
    artifact = AiArtifact.find(params[:id])
    artifact.destroy!
    path = artifact.interview_prep? ? edit_job_application_path(artifact.job_application, anchor: "entrevista") : job_posting_path(artifact.job_posting, anchor: "ia")
    redirect_to path, notice: t("flash.ai.deleted"), status: :see_other
  end

  # Lazy Turbo Frame with the cost per click: tokens estimated from the prompt size and
  # prices from OpenRouter's model list. No AI call is made here.
  def estimate
    if Ai::Client.configured? && !Ai::Client.free?
      prices = Ai::Pricing.for(Ai::Client.model)
      @estimates = allowed_kinds.index_with do |kind|
        text = Ai::Client.request_text(kind, @job_posting, application: @job_application)
        Ai::Pricing.estimate(kind, Ai::Pricing.estimate_tokens(text), prices)
      end
    end
    render layout: false
  end

  private
    def set_parent
      if params[:job_application_id]
        @job_application = JobApplication.find(params[:job_application_id])
        @job_posting = @job_application.job_posting
      else
        @job_posting = JobPosting.find(params[:job_posting_id])
      end
    end

    def allowed_kinds
      @job_application ? %w[interview_prep] : AiArtifact::POSTING_KINDS
    end

    def parent_path
      @job_application ? edit_job_application_path(@job_application, anchor: "entrevista") : job_posting_path(@job_posting, anchor: "ia")
    end
end
