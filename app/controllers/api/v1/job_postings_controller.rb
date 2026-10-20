module Api
  module V1
    # POST /api/v1/job_postings — "Salvar no WorkMachine" from the browser extension.
    class JobPostingsController < BaseController
      def create
        result = JobIngestor.call(job_posting_params.to_h.merge(source: "extension"))
        return render(json: { errors: result.posting.errors.full_messages }, status: :unprocessable_content) if result.invalid?

        posting = result.posting
        application = create_application(posting) if params[:create_application].to_s == "true"

        render json: {
          id: posting.id,
          title: posting.title,
          company: posting.company,
          score: posting.score,
          remote_scope: posting.human_enum(:remote_scope),
          duplicate: result.duplicate?,
          job_application_id: (application || posting.job_application)&.id,
          app_url: job_posting_url(posting)
        }, status: result.created? ? :created : :ok
      end

      private
        def job_posting_params
          params.expect(job_posting: %i[ title company url description location_text salary_text posted_at ])
        end

        def create_application(posting)
          posting.job_application || JobApplication.build_from_posting(posting).tap(&:save!).tap { posting.triage_saved! }
        end
    end
  end
end
