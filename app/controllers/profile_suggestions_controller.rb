# Perfil → Sugestões das suas triagens: apply one to the profile or dismiss it for good.
class ProfileSuggestionsController < ApplicationController
  def apply
    suggestion = find_suggestion or return redirect_to(profile_path, alert: t("flash.suggestions.gone"))

    ProfileSuggestions.new.apply(suggestion)
    redirect_to profile_path, notice: t("flash.suggestions.applied", term: suggestion.term)
  end

  def dismiss
    setting = Setting.current
    setting.update!(dismissed_suggestions: (setting.dismissed_suggestions + [ params.require(:key) ]).uniq)
    redirect_back_or_to profile_path, notice: t("flash.suggestions.dismissed")
  end

  private
    # Computed again (not from the cache), so only a suggestion that still holds is applied.
    def find_suggestion
      ProfileSuggestions.new.call.find { it.key == params.require(:key) }
    end
end
