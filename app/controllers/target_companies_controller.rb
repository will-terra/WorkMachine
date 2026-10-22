class TargetCompaniesController < ApplicationController
  before_action :set_target_company, only: %i[ edit update destroy activate dismiss ]

  def index
    @suggestions = TargetCompany.suggested.includes(:discovered_from).order(discovered_at: :desc)
    @target_companies = TargetCompany.alphabetical.where.not(id: @suggestions.select(:id))
    @stats = TargetCompany.posting_stats
  end

  def new
    @target_company = TargetCompany.new(ats: "greenhouse")
  end

  def create
    @target_company = TargetCompany.new(target_company_params)

    if @target_company.save
      redirect_to target_companies_path, notice: t("flash.targets.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @target_company.update(target_company_params)
      redirect_to target_companies_path, notice: t("flash.targets.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @target_company.destroy!
    redirect_to target_companies_path, notice: t("flash.targets.deleted"), status: :see_other
  end

  # "Procurar": with a name, asks the ATSs for that company now (the boards found become
  # suggestions); without one, checks every application again in the background.
  def find
    if params[:name].present?
      found = TargetCompanyFinder.new.search(params[:name])
      message = found.any? ? t("flash.targets.found", boards: found.map { "#{it.human_enum(:ats)}/#{it.board_slug}" }.to_sentence) : t("flash.targets.not_found", name: params[:name].strip)
      redirect_to target_companies_path, notice: message
    else
      JobApplication.where.not(status: "saved").update_all(board_checked_at: nil)
      FindTargetCompaniesJob.perform_later
      redirect_to target_companies_path, notice: t("flash.targets.searching")
    end
  end

  def activate
    @target_company.update!(active: true)
    redirect_to target_companies_path, notice: t("flash.targets.activated", name: @target_company.name)
  end

  # Keeps the company (inactive) so it is not suggested again.
  def dismiss
    @target_company.update!(discovered_at: nil)
    redirect_to target_companies_path, notice: t("flash.targets.dismissed"), status: :see_other
  end

  private
    def set_target_company
      @target_company = TargetCompany.find(params[:id])
    end

    def target_company_params
      params.expect(target_company: %i[ name ats board_slug active ])
    end
end
