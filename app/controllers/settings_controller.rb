class SettingsController < ApplicationController
  before_action :set_setting

  def show
    @push_subscriptions = PushSubscription.order(:created_at)
  end

  def update
    if @setting.update(params.expect(setting: %i[ notifications_enabled notify_min_score ]))
      redirect_to settings_path, notice: "Ajustes salvos."
    else
      @push_subscriptions = PushSubscription.order(:created_at)
      render :show, status: :unprocessable_content
    end
  end

  private
    def set_setting
      @setting = Setting.current
    end
end
