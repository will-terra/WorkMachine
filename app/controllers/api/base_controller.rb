module Api
  # JSON API used by the browser extension. Authenticates with
  # "Authorization: Bearer <WORKMACHINE_API_TOKEN>" instead of the session cookie.
  class BaseController < ActionController::API
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :authenticate_token!

    rate_limit to: 60, within: 1.minute, with: -> { render json: { error: "Muitas requisições. Tente de novo em um minuto." }, status: :too_many_requests }

    private
      def authenticate_token!
        expected = AppKeys.api_token.to_s
        if expected.blank?
          render json: { error: "Gere o token da extensão no WorkMachine, em Ajustes → Extensão do navegador." }, status: :service_unavailable
        else
          authenticate_or_request_with_http_token do |token, _options|
            ActiveSupport::SecurityUtils.secure_compare(token, expected)
          end
        end
      end

      def request_http_token_authentication(realm = "WorkMachine", _message = nil)
        headers["WWW-Authenticate"] = %(Bearer realm="#{realm}")
        render json: { error: "Token inválido. Confira o token nas opções da extensão." }, status: :unauthorized
      end
  end
end
