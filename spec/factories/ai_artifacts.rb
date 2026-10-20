FactoryBot.define do
  factory :ai_artifact do
    job_posting
    kind { "fit_analysis" }
    status { "completed" }
    content { "Boa aderência." }
    model { "deepseek/deepseek-v4-pro-0813" }
  end
end
