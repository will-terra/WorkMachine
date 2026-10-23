class ProfilesController < ApplicationController
  before_action :set_profile

  def show
    if params[:rascunho].present? && @profile.cv_draft.present?
      @profile.apply_draft
      @from_draft = true
    end
    @suggestions = @from_draft ? [] : ProfileSuggestions.current(@profile)
  end

  def update
    alerts_before = Radar.alert_searches(@profile).map { it["query"] }
    @profile.assign_attributes(profile_params)
    @profile.drop_default_overrides
    @profile.assign_attributes(cv_draft: nil, cv_draft_status: nil) if params[:from_draft].present?

    if @profile.save
      redirect_to profile_path, notice: [ rescore_notice, new_alerts_notice(alerts_before) ].compact.join(" ")
    else
      @from_draft = params[:from_draft].present?
      render :show, status: :unprocessable_content
    end
  end

  # "Ver prévia": what the form would change, without saving.
  def preview
    @preview = ProfilePreview.new(@profile, profile_params)
    render partial: "profiles/preview", locals: { preview: @preview }
  end

  # The CV card, reloaded while the AI draft is being made.
  def cv
    render partial: "profiles/cv", locals: { profile: @profile }
  end

  def upload_cv
    file = params.require(:cv)
    return redirect_to(profile_path(anchor: "cv"), alert: t("flash.profile.cv_too_big")) if file.size > Profile::MAX_CV_SIZE

    text = CvText.call(file.tempfile, filename: file.original_filename, content_type: file.content_type)
    file.tempfile.rewind
    @profile.cv.attach(file)
    @profile.update!(cv_text: text, cv_draft: nil, cv_draft_status: nil, cv_draft_error: nil)
    redirect_to profile_path(anchor: "cv"), notice: t("flash.profile.cv_read", count: text.length.to_fs(:delimited))
  rescue CvText::Error => e
    redirect_to profile_path(anchor: "cv"), alert: e.message
  end

  def draft
    return redirect_to(profile_path(anchor: "cv"), alert: t("flash.ai.no_key")) unless Ai::ProfileDraft.configured?
    return redirect_to(profile_path(anchor: "cv"), alert: t("flash.profile.cv_missing")) if @profile.cv_text.blank?

    @profile.update!(cv_draft_status: "pending", cv_draft_error: nil)
    ProfileDraftJob.perform_later(@profile)
    redirect_to profile_path(anchor: "cv"), notice: t("flash.profile.drafting")
  end

  def discard_draft
    @profile.update!(cv_draft: nil, cv_draft_status: nil, cv_draft_error: nil)
    redirect_to profile_path(anchor: "cv"), notice: t("flash.profile.draft_discarded")
  end

  private
    def set_profile
      @profile = Profile.current
      @profile.save! if @profile.new_record? && !action_name.in?(%w[show preview update])
    end

    def profile_params
      params.expect(profile: [
        :name, :headline, :location, :time_zone, :languages, :linkedin_url, :github_url, :portfolio_url,
        :primary_area, :plan_b_area, :target_titles, :target_titles_en, :seniority, :years_experience,
        :salary_brl_min, :salary_brl_max, :salary_usd_min, :salary_usd_max,
        :search_terms, :plan_b_terms, :domains, :ai_profile,
        work_modes: [], regions: [], avoid_terms: [], skills: [ [ :name, :level, :synonyms, :_destroy ] ],
        search_overrides: Radar.searches.map { it.fetch("key") }
      ])
    end

    # The profile changed the queries of the LinkedIn alerts: the new ones wait in the Radar.
    def new_alerts_notice(before)
      queries = Radar.alert_searches(@profile).map { it["query"] } - before
      count = queries.size - ActivatedAlert.where(query: queries).count
      t("flash.profile.new_alerts", count:) if count.positive?
    end

    def rescore_notice
      if @profile.saved_changes.keys.intersect?(Profile::SCORING_ATTRIBUTES)
        t("flash.profile.saved_rescoring", count: JobPosting.count)
      else
        t("flash.profile.saved")
      end
    end
end
