require "rails_helper"

RSpec.describe "Ajustes → keys, accounts and the extension token" do
  before { sign_in }

  let(:setting) { Setting.current }

  it "saves the keys encrypted and keeps a blank password as it was" do
    get settings_path
    expect(response.body).to include("Gratuito", "minimax/minimax-m3.1-flash:free", 'value="free" checked', "Instale pela", ExtensionVersion::STORE_URL)

    patch keys_settings_path, params: { setting: { openrouter_api_key: " sk-or-v1-abc ", openrouter_model: "z-ai/glm-5.3", ai_plan: "paid", gmail_user: "ana@gmail.com", gmail_app_password: "abcd efgh ijkl mnop" } }

    expect(response).to redirect_to(settings_path(anchor: "chaves"))
    expect(AppKeys.openrouter_api_key).to eq("sk-or-v1-abc")
    expect(AppKeys.gmail_app_password).to eq("abcdefghijklmnop")
    expect(Ai::Client.model).to eq("z-ai/glm-5.3")
    expect(Setting.connection.select_value("SELECT gmail_app_password FROM settings")).not_to include("abcdefgh")

    patch keys_settings_path, params: { setting: { openrouter_api_key: "", gmail_app_password: "", gmail_user: "ana@gmail.com", openrouter_model: "" }, clear: [ "gmail_user" ] }
    expect(AppKeys.openrouter_api_key).to eq("sk-or-v1-abc")
    expect(AppKeys.gmail_user).to be_nil
    expect(Ai::Client.model).to eq(Ai::Client::PAID_MODEL)

    patch keys_settings_path, params: { setting: { ai_plan: "free" } }
    expect(Ai::Client.model).to eq("minimax/minimax-m3.1-flash:free")

    get settings_path
    expect(response.body).to include("Chaves e contas", "salva; deixe vazio para manter", "Apagar")
  end

  it "prefers the variables of .env and shows it" do
    ENV["OPENROUTER_API_KEY"] = "da-env"
    setting.update!(openrouter_api_key: "da-tela")

    expect(AppKeys.openrouter_api_key).to eq("da-env")
    get settings_path
    expect(response.body).to include("definida no .env")
  ensure
    ENV.delete("OPENROUTER_API_KEY")
  end

  it "tests the OpenRouter key" do
    setting.update!(openrouter_api_key: "sk-or-v1-abc")
    stub_request(:get, "https://openrouter.ai/api/v1/key").with(headers: { "Authorization" => "Bearer sk-or-v1-abc" }).to_return(body: { data: { label: "minha" } }.to_json)

    post test_openrouter_settings_path
    expect(flash[:notice]).to include("OpenRouter conectado (minha)")

    stub_request(:get, "https://openrouter.ai/api/v1/key").to_return(status: 401, body: "{}")
    post test_openrouter_settings_path
    expect(flash[:alert]).to include("recusou a chave")
  end

  it "tests the Gmail login" do
    post test_gmail_settings_path
    expect(flash[:alert]).to include("Coloque o e-mail")

    setting.update!(gmail_user: "ana@gmail.com", gmail_app_password: "abcdefghijklmnop")
    imap = instance_double(Net::IMAP, login: true, examine: true, status: { "MESSAGES" => 1234 }, logout: true, disconnect: true, disconnected?: false)
    allow(Net::IMAP).to receive(:new).and_return(imap)

    post test_gmail_settings_path
    expect(flash[:notice]).to include("Gmail conectado: 1.234 e-mails")
  end

  it "generates the extension token that the API accepts" do
    get settings_path
    expect(response.body).to include("Gerar token", ExtensionVersion.current)

    post regenerate_token_settings_path
    token = setting.reload.api_token
    expect(token.length).to be >= 40

    get api_v1_ping_path, headers: { "Authorization" => "Bearer #{token}" }
    expect(response.parsed_body).to eq("ok" => true, "app" => "WorkMachine")
  end

  it "reads keys it cannot decrypt as not saved" do
    allow(Setting).to receive(:current).and_return(setting)
    allow(setting).to receive(:openrouter_api_key).and_raise(ActiveRecord::Encryption::Errors::Decryption)

    expect(AppKeys.openrouter_api_key).to be_nil
  end
end
