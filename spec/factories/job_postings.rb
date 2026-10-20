FactoryBot.define do
  factory :job_posting do
    sequence(:title) { |n| "Ruby on Rails Developer #{n}" }
    company { "Acme" }
    sequence(:url) { |n| "https://jobs.example.com/rails-#{n}" }
    source { "remotive" }
    remote_scope { "worldwide" }
    description { "We use Ruby on Rails, Hotwire and PostgreSQL." }
    posted_at { 1.day.ago }
    score { 50 }
  end
end
