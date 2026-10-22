class SettingsController < ApplicationController
  before_action :set_setting

  def show
    @push_subscriptions = PushSubscription.order(:created_at)
    @backups = DatabaseBackup.files
  end

  # Ajustes → Chaves e contas. A blank password field keeps what was saved; "apagar" clears it.
  def keys
    attributes = params.expect(setting: %i[ openrouter_api_key openrouter_model ai_plan gmail_user gmail_app_password ])
    attributes = attributes.reject { |field, value| value.blank? && field.in?(%w[openrouter_api_key gmail_app_password]) }
    Array(params[:clear]).each { attributes[it] = nil if it.in?(%w[openrouter_api_key gmail_user gmail_app_password]) }
    @setting.update!(attributes)
    redirect_to params[:return_to].presence_in([ onboarding_path ]) || settings_path(anchor: "chaves"), notice: "Chaves salvas."
  end

  def test_openrouter
    return redirect_to(settings_path(anchor: "chaves"), alert: "Coloque a chave do OpenRouter primeiro.") unless Ai::Client.configured?

    key = HttpClient.get_json("https://openrouter.ai/api/v1/key", headers: { "Authorization" => "Bearer #{AppKeys.openrouter_api_key}" }).fetch("data", {})
    redirect_to settings_path(anchor: "chaves"), notice: "OpenRouter conectado#{" (#{key["label"]})" if key["label"].present?}. Modelo: #{Ai::Client.model}."
  rescue HttpClient::Error => e
    redirect_to settings_path(anchor: "chaves"), alert: e.status == 401 ? "O OpenRouter recusou a chave. Confira se copiou inteira." : "Não consegui falar com o OpenRouter (#{e.message.truncate(120)})."
  end

  def test_gmail
    return redirect_to(settings_path(anchor: "chaves"), alert: "Coloque o e-mail e a senha de app do Gmail primeiro.") unless GmailSession.configured?

    count = GmailSession.open { |imap| imap.status(GmailSession.mailbox, [ "MESSAGES" ])["MESSAGES"] }
    redirect_to settings_path(anchor: "chaves"), notice: "Gmail conectado: #{count.to_i.to_fs(:delimited)} e-mails em #{GmailSession.mailbox}. Nada é alterado na caixa."
  rescue GmailSession::LoginError => e
    redirect_to settings_path(anchor: "chaves"), alert: e.message
  rescue Net::IMAP::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Timeout::Error => e
    redirect_to settings_path(anchor: "chaves"), alert: "Não consegui falar com o Gmail (#{e.class})."
  end

  def regenerate_token
    @setting.regenerate_api_token!
    redirect_to settings_path(anchor: "extensao"), notice: "Token novo gerado. Cole nas Opções da extensão."
  end

  def backup
    path = DatabaseBackup.call
    redirect_to settings_path, notice: "Backup feito: #{path.basename}."
  rescue StandardError => e
    redirect_to settings_path, alert: "O backup falhou: #{e.message.truncate(200)}"
  end

  def update
    if @setting.update(params.expect(setting: [ :notifications_enabled, :notify_min_score, :auto_dismiss_restricted, :auto_dismiss_below_score,
                                                :track_replies, :notify_replies, :notify_follow_ups, enabled_sources: [] ]))
      redirect_to settings_path, notice: "Ajustes salvos."
    else
      @push_subscriptions = PushSubscription.order(:created_at)
      @backups = DatabaseBackup.files
      render :show, status: :unprocessable_content
    end
  end

  private
    def set_setting
      @setting = Setting.current
      @profile = Profile.current
    end
end
