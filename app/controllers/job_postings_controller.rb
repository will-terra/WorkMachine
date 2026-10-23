class JobPostingsController < ApplicationController
  PER_PAGE = 50

  before_action :set_job_posting, only: %i[ show save apply dismiss restore dream undo ]

  # Triage: the postings with filters and ordering (JobPostingFilter) beside the detail of the
  # selected one (?selected=, or the first of the list).
  def index
    @filter = JobPostingFilter.new(filter_params)
    @page = [ params[:page].to_i, 0 ].max
    @total = @filter.scope.count
    @job_postings = @filter.ordered.limit(PER_PAGE).offset(@page * PER_PAGE).to_a
    @selected = JobPosting.find_by(id: params[:selected]) || @job_postings.first
    @ai_artifacts = @selected&.ai_artifacts&.for_posting&.latest_first
    @triage_counts = triage_counts
    @source_runs = SourceRun.latest_per_source.where(source: JobPosting::SOURCES)
  end

  # "Descartar todas": dismisses the new postings that match the current filters.
  def dismiss_all
    filter = JobPostingFilter.new(filter_params.merge("triage" => "new"))
    count = filter.scope.update_all(triage: "dismissed", updated_at: Time.current)
    redirect_to job_postings_path(filter.to_params),
                notice: t("flash.postings.dismissed_many", count:),
                status: :see_other
  end

  def show
    @ai_artifacts = @job_posting.ai_artifacts.for_posting.latest_first
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
      redirect_to job_posting_path(@job_posting), notice: result.created? ? t("flash.postings.added", score: @job_posting.score) : t("flash.postings.already_saved")
    end
  end

  def fetch
    FetchJobsJob.perform_later
    ImportLinkedinAlertsJob.perform_later if LinkedinAlerts::Importer.configured?
    redirect_to job_postings_path, notice: t("flash.postings.fetching")
  end

  def save
    undo = undo_params(application: true)
    application = @job_posting.save_as_application!
    respond_with_row(notice: t("flash.postings.saved", name: "#{application.company} · #{application.role}"), undo:)
  end

  def apply
    undo = undo_params(application: true)
    application = @job_posting.mark_applied!
    respond_with_row(notice: t("flash.postings.applied", name: "#{application.company} · #{application.role}", status: application.human_enum(:status).downcase), undo:)
  end

  # "Vaga dos sonhos": up to five postings the AI reads as the kind of role the person aims for.
  def dream
    profile = Profile.current
    profile.save! if profile.new_record?
    if profile.toggle_dream_posting!(@job_posting)
      notice = profile.dream_posting?(@job_posting) ? t("flash.postings.dream_added") : t("flash.postings.dream_removed")
      redirect_back_or_to job_posting_path(@job_posting), notice:
    else
      redirect_back_or_to job_posting_path(@job_posting), alert: t("flash.postings.dream_full", max: Profile::MAX_DREAM_POSTINGS)
    end
  end

  def dismiss
    undo = undo_params
    @job_posting.triage_dismissed!
    respond_with_row(notice: t("flash.postings.dismissed"), undo:)
  end

  def restore
    @job_posting.update!(triage: "new", auto_dismissed_reason: nil)
    respond_with_row(notice: t("flash.postings.restored"))
  end

  # "Desfazer" in the toast: the triage the posting had before and, when the action touched it,
  # the application as it was (removed if the action created it, moved back otherwise).
  def undo
    if params.key?(:application_id)
      application = @job_posting.job_application
      if params[:application_id].blank?
        application&.destroy!
      elsif application&.id == params[:application_id].to_i
        status = params[:status].presence_in(JobApplication::STATUSES) || application.status
        application.move_to!(status, JobApplication.where(status:).count) unless status == application.status
        application.update!(applied_on: params[:applied_on].presence)
      end
    end
    @job_posting.update!(triage: params[:triage].presence_in(JobPosting::TRIAGES) || "new")
    redirect_to back_with_posting_selected, notice: t("flash.postings.undone"), status: :see_other
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

    # How many postings each option of "Triagem" has.
    def triage_counts
      counts = JobPosting.group(:triage).count
      JobPosting::TRIAGES.index_with { counts.fetch(it, 0) }
        .merge("auto" => JobPosting.triage_dismissed.where.not(auto_dismissed_reason: nil).count, "all" => counts.values.sum)
    end

    # What "Desfazer" needs to put back: the triage and, for save and apply, the application.
    def undo_params(application: false)
      state = { "triage" => @job_posting.triage }
      if application
        current = @job_posting.job_application
        state.merge!("application_id" => current&.id.to_s, "status" => current&.status.to_s, "applied_on" => current&.applied_on&.iso8601.to_s)
      end
      state
    end

    # Triage from the Painel goes back to it; from Vagas, the list and the detail change in place.
    def respond_with_row(notice:, undo: nil)
      undo &&= { "url" => undo_job_posting_path(@job_posting), "params" => undo }
      return redirect_to(root_path, notice:, flash: { undo: }, status: :see_other) if params[:from] == "painel"

      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = notice
          flash.now[:undo] = undo
          render turbo_stream: [
            turbo_stream.replace("posting_detail", partial: "job_postings/detail",
                                                   locals: { job_posting: @job_posting, ai_artifacts: @job_posting.ai_artifacts.for_posting.latest_first, standalone: params[:standalone].present? }),
            turbo_stream.replace(@job_posting, partial: "job_postings/job_posting", locals: { job_posting: @job_posting }),
            *triage_counts.map { |triage, count| turbo_stream.update("triage_count_#{triage}", count.to_s) },
            turbo_stream.update("nav_count", JobPosting.triage_new.count.nonzero?.to_s),
            turbo_stream.replace("flash", partial: "layouts/flash")
          ]
        end
        format.html { redirect_back_or_to job_posting_path(@job_posting), notice:, flash: { undo: } }
      end
    end

    # Back to the page of the toast; on Vagas, with the posting selected again.
    def back_with_posting_selected
      uri = URI.parse(request.referer.to_s)
      return root_path if uri.path == root_path
      return job_posting_path(@job_posting) unless uri.path == job_postings_path

      job_postings_path(Rack::Utils.parse_query(uri.query).slice(*JobPostingFilter::KEYS, "page").merge("selected" => @job_posting.id))
    rescue URI::InvalidURIError
      job_posting_path(@job_posting)
    end
end
