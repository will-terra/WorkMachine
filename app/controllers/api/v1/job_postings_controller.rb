module Api
  module V1
    # POST /api/v1/job_postings — "Salvar no WorkMachine" from the browser extension.
    # GET /api/v1/job_postings/lookup — whether the open job is already here (popup and icon badge).
    class JobPostingsController < BaseController
      APPLICATION_STATUSES = %w[saved applied].freeze

      def create
        result = JobIngestor.call(job_posting_params.to_h.merge(source: "extension"))
        return render(json: { errors: result.posting.errors.full_messages }, status: :unprocessable_content) if result.invalid?

        posting = result.posting
        case application_status
        when "saved" then posting.save_as_application!
        when "applied" then posting.mark_applied!
        end

        render json: posting_json(posting).merge(duplicate: result.duplicate?), status: result.created? ? :created : :ok
      end

      # Same matching as the ingestor: normalized URL, or company + title.
      def lookup
        posting = JobPosting.find_duplicate(url: params[:url], company: params[:company], title: params[:title])
        render json: posting ? posting_json(posting).merge(found: true) : { found: false }
      end

      private
        def job_posting_params
          params.expect(job_posting: %i[ title company url description location_text salary_text posted_at ])
        end

        # create_application=true is how the 1.0 extension asks for "saved".
        def application_status
          status = params[:application_status].presence || ("saved" if params[:create_application].to_s == "true")
          status if APPLICATION_STATUSES.include?(status)
        end

        def posting_json(posting)
          application = posting.job_application
          {
            id: posting.id,
            title: posting.title,
            company: posting.company,
            score: posting.score,
            partial_score: posting.partial_score?,
            remote_scope: posting.human_enum(:remote_scope),
            triage: posting.triage,
            job_application_id: application&.id,
            application_status: application&.status,
            summary: summary(posting, application),
            app_url: job_posting_url(posting)
          }
        end

        def summary(posting, application)
          if application
            applied_on = I18n.t("api.summary.applied_on", date: I18n.l(application.applied_on, format: :day_month)) if application.applied_on
            I18n.t("api.summary.application", status: application.human_enum(:status), applied_on:)
          elsif posting.auto_dismissed_reason && posting.triage_dismissed?
            I18n.t("api.summary.auto_dismissed", reason: JobScorer.human_term(posting.auto_dismissed_reason))
          else
            posting.triage_new? ? I18n.t("api.summary.new") : posting.human_enum(:triage)
          end
        end
    end
  end
end
