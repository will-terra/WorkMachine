require "rails_helper"

RSpec.describe "Setups" do
  it "shows the account form on first run" do
    get new_setup_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Crie sua conta")
  end

  it "creates the single user and signs in" do
    expect {
      post setup_path, params: { user: { email_address: "ana@example.com", password: "senha-segura-123", password_confirmation: "senha-segura-123" } }
    }.to change(User, :count).by(1)

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("Painel")
  end

  it "re-renders the form when the data is invalid" do
    post setup_path, params: { user: { email_address: "ana@example.com", password: "curta", password_confirmation: "outra" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(User.count).to eq(0)
  end

  it "is closed once a user exists" do
    create(:user)

    get new_setup_path
    expect(response).to redirect_to(new_session_path)

    expect {
      post setup_path, params: { user: { email_address: "intruso@example.com", password: "senha-segura-123", password_confirmation: "senha-segura-123" } }
    }.not_to change(User, :count)
  end
end
