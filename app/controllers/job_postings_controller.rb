class JobPostingsController < ApplicationController
  PER_PAGE = 50

  before_action :set_job_posting, only: %i[ show save dismiss restore ]

  # Triage: new postings, with filters and ordering (JobPostingFilter).
  def index
    @filter = JobPostingFilter.new(filter_params)
    @page = [ params[:page].to_i, 0 ].max
    @total = @filter.scope.count
    @job_postings = @filter.ordered.limit(PER_PAGE).offset(@page * PER_PAGE)
    @source_runs = SourceRun.latest_per_source
  end

  # "Descartar todas": dismisses the new postings that match the current filters.
  def dismiss_all
    filter = JobPostingFilter.new(filter_params.merge("triage" => "new"))
    count = filter.scope.update_all(triage: "dismissed", updated_at: Time.current)
    redirect_to job_postings_path(filter.to_params),
                notice: "#{count} #{count == 1 ? "vaga descartada" : "vagas descartadas"}. Elas continuam em Triagem → Descartada.",
                status: :see_other
  end

  def show
    @ai_artifacts = @job_posting.ai_artifacts.latest_first
  end

  def new
    @job_posting = JobPosting.new
  end

  def create
    result = JobIngestor.call(job_posting_params.to_h.merge(source: "manual"))
    @job_posting = result.posting

    if result.invalid?
      render :new, status: :unprocessable_content
    else
      redirect_to job_posting_path(@job_posting), notice: result.created? ? "Vaga adicionada com nota #{@job_posting.score}." : "Essa vaga já estava salva."
    end
  end

  def fetch
    FetchJobsJob.perform_later
    ImportLinkedinAlertsJob.perform_later if LinkedinAlerts::Importer.configured?
    redirect_to job_postings_path, notice: "Busca iniciada. As fontes respeitam o intervalo mínimo de cada uma; recarregue em um minuto."
  end

  def save
    application = @job_posting.job_application || JobApplication.build_from_posting(@job_posting).tap(&:save!)
    @job_posting.triage_saved!
    respond_with_row(notice: "Salva em Candidaturas: #{application.company} · #{application.role}.")
  end

  def dismiss
    @job_posting.triage_dismissed!
    respond_with_row(notice: "Vaga descartada.")
  end

  def restore
    @job_posting.triage_new!
    respond_with_row(notice: "Vaga de volta para a triagem.")
  end

  private
    def set_job_posting
      @job_posting = JobPosting.find(params[:id])
    end

    def job_posting_params
      params.expect(job_posting: %i[ title company url location_text salary_text description ])
    end

    def filter_params
      params.permit(*JobPostingFilter::KEYS).to_h
    end

    def respond_with_row(notice:)
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = notice
          render turbo_stream: [
            turbo_stream.replace(@job_posting, partial: "job_postings/job_posting", locals: { job_posting: @job_posting }),
            turbo_stream.replace("flash", partial: "layouts/flash")
          ]
        end
        format.html { redirect_back_or_to job_posting_path(@job_posting), notice: }
      end
    end
end
