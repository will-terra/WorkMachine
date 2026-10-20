require "rails_helper"

RSpec.describe "Sessions" do
  describe "GET /session/new" do
    it "sends to the first-run setup when there is no user" do
      get new_session_path

      expect(response).to redirect_to(new_setup_path)
    end

    it "shows the login form when the user exists" do
      create(:user)

      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Entrar no WorkMachine")
    end
  end

  describe "POST /session" do
    let!(:user) { create(:user) }

    it "signs in with the right password" do
      post session_path, params: { email_address: user.email_address, password: user.password }

      expect(response).to redirect_to(root_url)
      expect(cookies[:session_id]).to be_present
    end

    it "rejects a wrong password" do
      post session_path, params: { email_address: user.email_address, password: "errada-123" }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("E-mail ou senha incorretos.")
    end
  end

  describe "DELETE /session" do
    it "signs out" do
      user = sign_in

      expect { delete session_path }.to change { user.sessions.count }.by(-1)
      expect(response).to redirect_to(new_session_path)
    end
  end

  it "redirects anonymous visitors to the login" do
    create(:user)

    get root_path

    expect(response).to redirect_to(new_session_path)
  end
end
