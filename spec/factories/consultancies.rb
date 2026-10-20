FactoryBot.define do
  factory :consultancy do
    sequence(:name) { |n| "Consultoria #{n}" }
    url { "https://consultoria.example.com" }
    kind { "tech" }
  end
end
