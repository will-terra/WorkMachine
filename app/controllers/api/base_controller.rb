module Api
  # JSON API used by the browser extension. Authenticates with
  # "Authorization: Bearer <WORKMACHINE_API_TOKEN>" instead of the session cookie.
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    around_action :switch_locale
    before_action :authenticate_token!

    rate_limit to: 60, within: 1.minute, with: -> { render json: { error: I18n.t("api.rate_limited") }, status: :too_many_requests }

    private
      # The extension's requests carry the browser's language, like the pages.
      def switch_locale(&)
        I18n.with_locale(LocalePreference.for_request(request.headers["Accept-Language"]), &)
      end

      def authenticate_token!
        expected = AppKeys.api_token.to_s
        if expected.blank?
          render json: { error: I18n.t("api.no_token") }, status: :service_unavailable
        else
          authenticate_or_request_with_http_token do |token, _options|
            ActiveSupport::SecurityUtils.secure_compare(token, expected)
          end
        end
      end

      def request_http_token_authentication(realm = "WorkMachine", _message = nil)
        headers["WWW-Authenticate"] = %(Bearer realm="#{realm}")
        render json: { error: I18n.t("api.invalid_token") }, status: :unauthorized
      end
  end
end
