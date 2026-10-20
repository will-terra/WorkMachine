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
      redirect_to target_companies_path, notice: "Empresa adicionada. Ela entra na próxima busca."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @target_company.update(target_company_params)
      redirect_to target_companies_path, notice: "Empresa atualizada."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @target_company.destroy!
    redirect_to target_companies_path, notice: "Empresa removida.", status: :see_other
  end

  def activate
    @target_company.update!(active: true)
    redirect_to target_companies_path, notice: "#{@target_company.name} ativada. Ela entra na próxima busca."
  end

  # Keeps the company (inactive) so it is not suggested again.
  def dismiss
    @target_company.update!(discovered_at: nil)
    redirect_to target_companies_path, notice: "Sugestão ignorada.", status: :see_other
  end

  private
    def set_target_company
      @target_company = TargetCompany.find(params[:id])
    end

    def target_company_params
      params.expect(target_company: %i[ name ats board_slug active ])
    end
end
