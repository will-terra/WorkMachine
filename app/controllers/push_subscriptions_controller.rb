# Browsers that receive desktop notifications. Called by push_controller.js after the
# browser grants permission (Web Push subscription JSON: endpoint + keys).
class PushSubscriptionsController < ApplicationController
  def create
    subscription = PushSubscription.find_or_initialize_by(endpoint: params.require(:endpoint))
    keys = params.require(:keys)
    subscription.update!(p256dh: keys.require(:p256dh), auth: keys.require(:auth), user_agent: request.user_agent)
    render json: { ok: true, id: subscription.id }
  end

  # DELETE with the endpoint, from the browser that is turning notifications off.
  def unsubscribe
    PushSubscription.where(endpoint: params.require(:endpoint)).destroy_all
    render json: { ok: true }
  end

  # Removes another browser from the settings page.
  def destroy
    PushSubscription.find(params[:id]).destroy!
    redirect_to settings_path, notice: t("flash.push.removed"), status: :see_other
  end

  def test
    delivered = PushSender.deliver_all(title: "WorkMachine", body: t("flash.push.test", min: Setting.current.notify_min_score), path: "/vagas", tag: "test")
    render json: { ok: delivered.positive?, delivered: }
  end
end
