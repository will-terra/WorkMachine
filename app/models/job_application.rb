class JobApplication < ApplicationRecord
  STATUSES = %w[saved applied recruiter_contact hr_interview tech_interview take_home
                offer rejected no_response withdrawn].freeze
  CLOSED_STATUSES = %w[rejected no_response withdrawn].freeze
  OPEN_STATUSES = (STATUSES - CLOSED_STATUSES).freeze
  FOLLOW_UP_AFTER = 5.days

  enum :status, STATUSES.index_by(&:itself), prefix: true, validate: true

  belongs_to :job_posting, optional: true

  validates :company, :role, presence: true

  before_validation :set_position, on: :create
  before_save :set_applied_on

  scope :in_progress, -> { where(status: OPEN_STATUSES) }
  scope :ordered, -> { order(:position, :id) }
  scope :follow_up_due, ->(date = Date.current) { in_progress.where(next_follow_up_on: ..date) }
  # Applied more than FOLLOW_UP_AFTER ago, still without any answer or follow-up date.
  scope :waiting_answer, ->(date = Date.current) {
    status_applied.where(applied_on: ..(date - FOLLOW_UP_AFTER), next_follow_up_on: nil)
  }

  def self.build_from_posting(posting)
    new(
      job_posting: posting,
      company: posting.display_company,
      role: posting.title,
      origin: posting.human_enum(:source)
    )
  end

  # Moves the card to a kanban column and reorders that column.
  def move_to!(new_status, index)
    transaction do
      ids = self.class.where(status: new_status).where.not(id: id).ordered.pluck(:id)
      ids.insert(index.to_i.clamp(0, ids.size), id)
      update!(status: new_status)
      ids.each_with_index { |card_id, position| self.class.where(id: card_id).update_all(position: position) }
    end
  end

  def url
    contact_url.presence || job_posting&.url
  end

  private
    def set_position
      self.position = (self.class.where(status: status).maximum(:position) || -1) + 1
    end

    def set_applied_on
      self.applied_on ||= Date.current if status_applied? && will_save_change_to_status?
    end
end
