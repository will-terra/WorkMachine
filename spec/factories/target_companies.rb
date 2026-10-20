FactoryBot.define do
  factory :target_company do
    name { "GitLab" }
    ats { "greenhouse" }
    sequence(:board_slug) { |n| "company#{n}" }
  end
end
