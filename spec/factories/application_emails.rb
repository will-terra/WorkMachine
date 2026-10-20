FactoryBot.define do
  factory :application_email do
    job_application
    sequence(:message_id) { |n| "msg-#{n}@mail.example.com" }
    from_name { "Acme Recruiting" }
    from_address { "jobs@acme.com" }
    subject { "Atualização da sua candidatura" }
    received_at { 1.day.ago }
    category { "other" }
    classified_by { "ai" }
  end
end
