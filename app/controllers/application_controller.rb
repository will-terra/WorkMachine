class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  around_action :use_profile_time_zone

  private
    # Dates and times on screen follow the time zone of the profile (Perfil → Fuso horário).
    def use_profile_time_zone(&)
      Time.use_zone(Profile.current.time_zone, &)
    end
end
