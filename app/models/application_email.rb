# An e-mail from a company you applied to, read from Gmail and classified
# (ApplicationReplies::Importer). Unrelated ones are kept only so they are not read again.
class ApplicationEmail < ApplicationRecord
  CATEGORIES = %w[rejection interview assessment offer recruiter_contact confirmation other unrelated].freeze
  # Replies that mean the company answered (they move the card and count as a response).
  ANSWERS = %w[rejection interview assessment offer recruiter_contact].freeze

  enum :category, CATEGORIES.index_by(&:itself), prefix: true, validate: true

  belongs_to :job_application

  validates :message_id, presence: true, uniqueness: true

  scope :visible, -> { where.not(category: "unrelated") }
  scope :answers, -> { where(category: ANSWERS) }
  scope :latest_first, -> { order(received_at: :desc, id: :desc) }

  def status_changed?
    status_after.present? && status_after != status_before
  end
end
