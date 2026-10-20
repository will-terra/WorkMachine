class JobPostingsController < ApplicationController
  PER_PAGE = 50

  before_action :set_job_posting, only: %i[ show save dismiss restore ]

  # Triage: new postings by score, with filters.
  def index
    @filters = params.permit(:triage, :source, :remote_scope, :seniority, :min_score, :q, :page).to_h
    @filters["triage"] = "new" unless JobPosting::TRIAGES.include?(@filters["triage"]) || @filters["triage"] == "all"
    @page = [ @filters["page"].to_i, 0 ].max
    scope = filtered_postings
    @total = scope.count
    @job_postings = scope.ranked.limit(PER_PAGE).offset(@page * PER_PAGE)
    @source_runs = SourceRun.latest_per_source
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

    def filtered_postings
      scope = JobPosting.all
      scope = scope.where(triage: @filters["triage"]) unless @filters["triage"] == "all"
      scope = scope.where(source: @filters["source"]) if @filters["source"].present?
      scope = scope.where(remote_scope: @filters["remote_scope"]) if @filters["remote_scope"].present?
      scope = scope.where(seniority: @filters["seniority"]) if @filters["seniority"].present?
      scope = scope.where(score: @filters["min_score"].to_i..) if @filters["min_score"].present?
      if @filters["q"].present?
        term = "%#{JobPosting.sanitize_sql_like(@filters["q"])}%"
        scope = scope.where("title LIKE :term OR company LIKE :term OR description LIKE :term", term:)
      end
      scope
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
