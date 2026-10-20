FactoryBot.define do
  factory :message_template do
    sequence(:name) { |n| "Modelo #{n}" }
    language { "pt" }
    body { "Oi, {{nome}}! Vi a vaga de {{cargo}} na {{empresa}}." }
  end
end
