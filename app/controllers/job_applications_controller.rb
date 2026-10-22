class JobApplicationsController < ApplicationController
  VIEWS = %w[board table].freeze

  before_action :set_job_application, only: %i[ edit update destroy move ]

  def index
    @view = VIEWS.include?(params[:view]) ? params[:view] : "board"
    @job_applications = filtered_applications

    respond_to do |format|
      format.html { @columns = @job_applications.ordered.group_by(&:status) if @view == "board" }
      format.xlsx { render xlsx: "index", filename: "candidaturas-#{Date.current.iso8601}.xlsx" }
      format.csv { send_data JobApplicationCsv.export(@job_applications.latest_first), filename: "candidaturas-#{Date.current.iso8601}.csv", type: "text/csv; charset=utf-8" }
    end
  end

  def new
    @job_application = JobApplication.new(status: params[:status].presence_in(JobApplication::STATUSES) || "saved")
  end

  def create
    @job_application = JobApplication.new(job_application_params)

    if @job_application.save
      redirect_to job_applications_path, notice: t("flash.applications.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @job_application.update(job_application_params)
      redirect_to return_path, notice: t("flash.applications.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @job_application.destroy!
    redirect_to job_applications_path, notice: t("flash.applications.deleted"), status: :see_other
  end

  # Kanban drag and drop: PATCH status + position, answers with Turbo Streams for the touched columns.
  def move
    status = params.require(:status)
    return head :unprocessable_content unless JobApplication::STATUSES.include?(status)

    @previous_status = @job_application.status
    @job_application.move_to!(status, params.require(:position))
    @counts = JobApplication.where(status: [ @previous_status, status ].uniq).group(:status).count
  end

  def check_replies
    ImportApplicationRepliesJob.perform_later
    redirect_to job_applications_path(view: params[:view].presence_in(VIEWS)), notice: t("flash.applications.checking_replies")
  end

  def import
    file = params[:file]
    return redirect_to(job_applications_path(view: "table"), alert: t("flash.applications.choose_csv")) if file.blank?

    result = JobApplicationCsv.import(file.read)
    flash[:notice] = t("flash.applications.imported", count: result.created) if result.created.positive?
    flash[:alert] = result.errors.first(5).join(" · ") if result.errors.any?
    redirect_to job_applications_path(view: "table")
  end

  private
    def set_job_application
      @job_application = JobApplication.find(params[:id])
    end

    def filtered_applications
      scope = JobApplication.includes(:job_posting)
      scope = scope.where(status: params[:status]) if params[:status].present?
      if params[:q].present?
        term = "%#{JobApplication.sanitize_sql_like(params[:q])}%"
        scope = scope.where("company LIKE :term OR role LIKE :term OR contact_name LIKE :term", term:)
      end
      scope
    end

    # The status select of the table sends the page it is on (with its filters) to come back to.
    def return_path
      query = Rack::Utils.parse_query(URI.parse(params[:return_to].to_s).query.to_s).slice("view", "status", "q")
      job_applications_path({ "view" => params[:return_view].presence_in(VIEWS) }.compact.merge(query))
    rescue URI::InvalidURIError
      job_applications_path(view: params[:return_view].presence_in(VIEWS))
    end

    def job_application_params
      params.expect(job_application: %i[ company role origin status applied_on next_follow_up_on
                                         contact_name contact_url salary_range notes ])
    end
end
