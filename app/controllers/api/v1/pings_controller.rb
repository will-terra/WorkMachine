module Api
  module V1
    # Lets the extension's options page test the server URL and the token.
    class PingsController < BaseController
      def show
        render json: { ok: true, app: "WorkMachine" }
      end
    end
  end
end
