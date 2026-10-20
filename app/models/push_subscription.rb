# A browser that accepted desktop notifications (Web Push).
class PushSubscription < ApplicationRecord
  validates :endpoint, :p256dh, :auth, presence: true
  validates :endpoint, uniqueness: true

  def browser_name
    case user_agent.to_s
    when /Edg\//i then "Edge"
    when /Chrome\//i then "Chrome"
    when /Firefox\//i then "Firefox"
    when /Safari\//i then "Safari"
    else "Navegador"
    end
  end
end
