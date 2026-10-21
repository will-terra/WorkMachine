# Primeiro uso: the steps a new installation goes through (keys, profile, first search), each one
# also reachable later in Ajustes and Perfil.
class OnboardingsController < ApplicationController
  def show
    @setting = Setting.current
    @profile = Profile.current
    @steps = {
      keys: Ai::Client.configured?,
      gmail: GmailSession.configured?,
      profile: @profile.configured?,
      search: SourceRun.exists?
    }
  end

  def finish
    if params[:search].present? && Profile.current.configured?
      FetchJobsJob.perform_later(force: true)
      notice = "Primeira busca iniciada. As vagas chegam em Vagas em alguns minutos, já com nota."
    end
    Setting.current.update!(onboarded_at: Time.current)
    redirect_to(params[:search].present? ? job_postings_path : root_path, notice: notice || "Tudo pronto.")
  end
end
