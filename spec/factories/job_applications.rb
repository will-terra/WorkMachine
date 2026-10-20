FactoryBot.define do
  factory :job_application do
    company { "Acme" }
    sequence(:role) { |n| "Full Stack Engineer #{n}" }
    origin { "LinkedIn" }
    status { "saved" }
  end
end
