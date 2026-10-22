class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :switch_locale
  around_action :use_profile_time_zone

  private
    # Ajustes → Idioma, or the browser's language (LocalePreference).
    def switch_locale(&)
      I18n.with_locale(LocalePreference.for_request(request.headers["Accept-Language"]), &)
    end

    # Dates and times on screen follow the time zone of the profile (Perfil → Fuso horário).
    def use_profile_time_zone(&)
      Time.use_zone(Profile.current.time_zone, &)
    end
end
