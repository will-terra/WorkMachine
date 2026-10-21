class ProfilesController < ApplicationController
  before_action :set_profile

  def show
  end

  def update
    @profile.assign_attributes(profile_params)
    @profile.drop_default_overrides

    if @profile.save
      redirect_to profile_path, notice: rescore_notice
    else
      render :show, status: :unprocessable_content
    end
  end

  # "Ver prévia": what the form would change, without saving.
  def preview
    @preview = ProfilePreview.new(@profile, profile_params)
    render partial: "profiles/preview", locals: { preview: @preview }
  end

  private
    def set_profile
      @profile = Profile.current
    end

    def profile_params
      params.expect(profile: [
        :name, :headline, :location, :time_zone, :languages, :linkedin_url, :github_url, :portfolio_url,
        :primary_area, :plan_b_area, :target_titles, :target_titles_en, :seniority, :years_experience,
        :salary_brl_min, :salary_brl_max, :salary_usd_min, :salary_usd_max,
        :avoid_terms, :search_terms, :plan_b_terms, :domains, :ai_profile,
        work_modes: [], regions: [], skills: [ [ :name, :level, :synonyms, :_destroy ] ],
        search_overrides: Radar.searches.map { it.fetch("key") }
      ])
    end

    def rescore_notice
      if @profile.saved_changes.keys.intersect?(Profile::SCORING_ATTRIBUTES)
        "Perfil salvo. As notas das vagas estão sendo recalculadas."
      else
        "Perfil salvo."
      end
    end
end
