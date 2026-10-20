FactoryBot.define do
  factory :push_subscription do
    sequence(:endpoint) { |n| "https://fcm.googleapis.com/fcm/send/abc#{n}" }
    p256dh { "BNcRdreALRFXTkOOUHK1EtK2wtaz5Ry4YfYCA_0QTpQtUbVlUls0VJXg7A8u-Ts1XbjhazAkj7I99e8QcYP7DkM" }
    auth { "tBHItJI5svbpez7KI4CCXg" }
    user_agent { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Safari/537.36" }
  end
end
