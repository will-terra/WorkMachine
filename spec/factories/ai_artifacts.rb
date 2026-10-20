FactoryBot.define do
  factory :ai_artifact do
    job_posting
    kind { "fit_analysis" }
    status { "completed" }
    content { "Boa aderência." }
    model { "claude-sonnet" }
  end
end
