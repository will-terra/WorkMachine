class AiArtifact < ApplicationRecord
  enum :kind, { fit_analysis: "fit_analysis", cv_summary: "cv_summary", message: "message" }, validate: true
  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, prefix: true, validate: true

  belongs_to :job_posting

  scope :latest_first, -> { order(created_at: :desc, id: :desc) }
end
