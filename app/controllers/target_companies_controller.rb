class TargetCompaniesController < ApplicationController
  before_action :set_target_company, only: %i[ edit update destroy ]

  def index
    @target_companies = TargetCompany.alphabetical
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

  private
    def set_target_company
      @target_company = TargetCompany.find(params[:id])
    end

    def target_company_params
      params.expect(target_company: %i[ name ats board_slug active ])
    end
end
