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
    redirect_to params[:return_to].presence_in([ onboarding_path ]) || settings_path(anchor: "chaves"), notice: t("flash.settings.keys_saved")
  end

  def test_openrouter
    return redirect_to(settings_path(anchor: "chaves"), alert: t("flash.settings.openrouter_missing")) unless Ai::Client.configured?

    key = HttpClient.get_json("https://openrouter.ai/api/v1/key", headers: { "Authorization" => "Bearer #{AppKeys.openrouter_api_key}" }).fetch("data", {})
    redirect_to settings_path(anchor: "chaves"), notice: t("flash.settings.openrouter_ok", label: (" (#{key["label"]})" if key["label"].present?), model: Ai::Client.model)
  rescue HttpClient::Error => e
    redirect_to settings_path(anchor: "chaves"), alert: e.status == 401 ? t("flash.settings.openrouter_refused") : t("flash.settings.openrouter_failed", error: e.message.truncate(120))
  end

  def test_gmail
    return redirect_to(settings_path(anchor: "chaves"), alert: t("flash.settings.gmail_missing")) unless GmailSession.configured?

    count = GmailSession.open { |imap| imap.status(GmailSession.mailbox, [ "MESSAGES" ])["MESSAGES"] }
    redirect_to settings_path(anchor: "chaves"), notice: t("flash.settings.gmail_ok", count: count.to_i.to_fs(:delimited), mailbox: GmailSession.mailbox)
  rescue GmailSession::LoginError => e
    redirect_to settings_path(anchor: "chaves"), alert: e.message
  rescue Net::IMAP::Error, SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Timeout::Error => e
    redirect_to settings_path(anchor: "chaves"), alert: t("flash.settings.gmail_failed", error: e.class)
  end

  def regenerate_token
    @setting.regenerate_api_token!
    redirect_to settings_path(anchor: "extensao"), notice: t("flash.settings.token")
  end

  def backup
    path = DatabaseBackup.call
    redirect_to settings_path, notice: t("flash.settings.backup_done", file: path.basename)
  rescue StandardError => e
    redirect_to settings_path, alert: t("flash.settings.backup_failed", error: e.message.truncate(200))
  end

  def update
    if @setting.update(params.expect(setting: [ :notifications_enabled, :notify_min_score, :auto_dismiss_restricted, :auto_dismiss_below_score,
                                                :track_replies, :notify_replies, :notify_follow_ups, :notify_interviews, :locale, enabled_sources: [] ]))
      redirect_to settings_path, notice: t("flash.settings.saved")
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
