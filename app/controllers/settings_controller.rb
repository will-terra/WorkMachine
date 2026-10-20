class SettingsController < ApplicationController
  before_action :set_setting

  def show
    @push_subscriptions = PushSubscription.order(:created_at)
    @backups = DatabaseBackup.files
  end

  def backup
    path = DatabaseBackup.call
    redirect_to settings_path, notice: "Backup feito: #{path.basename}."
  rescue StandardError => e
    redirect_to settings_path, alert: "O backup falhou: #{e.message.truncate(200)}"
  end

  def update
    if @setting.update(params.expect(setting: %i[ notifications_enabled notify_min_score auto_dismiss_restricted auto_dismiss_below_score
                                                   track_replies notify_replies notify_follow_ups ]))
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
    end
end
