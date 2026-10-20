FactoryBot.define do
  factory :contact do
    name { "Mariana Souza" }
    company { "Acme" }
    sequence(:linkedin_url) { |n| "https://www.linkedin.com/in/mariana-#{n}" }
    kind { "recruiter" }
  end
end
