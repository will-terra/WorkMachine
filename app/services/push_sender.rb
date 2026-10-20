# Delivers a Web Push message to every subscribed browser and forgets the ones that expired.
module PushSender
  module_function

  # message: { title:, body:, path:, tag: }. Returns how many browsers accepted it.
  def deliver_all(message)
    vapid = Setting.current.vapid_keys!
    payload = message.to_json

    PushSubscription.find_each.count do |subscription|
      WebPush.payload_send(message: payload, endpoint: subscription.endpoint, p256dh: subscription.p256dh,
                           auth: subscription.auth, vapid:, ttl: 1.day.to_i, urgency: "normal",
                           open_timeout: 5, read_timeout: 10)
      subscription.update!(last_sent_at: Time.current)
      true
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      subscription.destroy!
      false
    rescue WebPush::Error, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError => e
      Rails.logger.warn("[PushSender] #{subscription.browser_name}: #{e.class} #{e.message.truncate(200)}")
      false
    end
  end
end
