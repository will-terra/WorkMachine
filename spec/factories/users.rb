FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "pessoa#{n}@example.com" }
    password { "senha-segura-123" }
  end
end
