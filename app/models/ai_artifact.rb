class AiArtifact < ApplicationRecord
  enum :kind, { fit_analysis: "fit_analysis", cv_summary: "cv_summary", message: "message", interview_prep: "interview_prep", tailored_cv: "tailored_cv" }, validate: true
  # The ones made from the posting page (Vagas → IA); the interview preparation lives on the application.
  POSTING_KINDS = %w[fit_analysis cv_summary tailored_cv message].freeze

  enum :status, { pending: "pending", completed: "completed", failed: "failed" }, prefix: true, validate: true

  # Most results belong to a posting; an interview preparation belongs to the application (whose
  # posting may be missing when it was typed by hand).
  belongs_to :job_posting, optional: true
  belongs_to :job_application, optional: true

  validates :job_posting, presence: true, unless: :job_application
  validates :job_application, presence: true, if: :interview_prep?

  scope :for_posting, -> { where(kind: POSTING_KINDS) }
  scope :latest_first, -> { order(created_at: :desc, id: :desc) }
end
