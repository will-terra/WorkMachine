class JobApplication < ApplicationRecord
  STATUSES = %w[saved applied recruiter_contact ai_interview hr_interview tech_interview take_home
                offer rejected no_response withdrawn].freeze
  CLOSED_STATUSES = %w[rejected no_response withdrawn].freeze
  # Statuses that mean the company answered (responded_on, funnel metrics).
  RESPONSE_STATUSES = %w[recruiter_contact ai_interview hr_interview tech_interview take_home offer rejected].freeze
  OPEN_STATUSES = (STATUSES - CLOSED_STATUSES).freeze
  # Stages to prepare for (Preparar entrevista).
  INTERVIEW_STATUSES = %w[ai_interview hr_interview tech_interview take_home].freeze
  # The interview reminder goes out from 6 p.m. the day before.
  REMIND_BEFORE = 6.hours
  FOLLOW_UP_AFTER = 5.days

  enum :status, STATUSES.index_by(&:itself), prefix: true, validate: true

  belongs_to :job_posting, optional: true
  has_many :application_emails, dependent: :destroy
  has_many :ai_artifacts, dependent: :destroy

  validates :company, :role, presence: true

  before_validation :set_position, on: :create
  before_save :set_applied_on, :set_responded_on
  # A new interview date gets its own reminder (written even when this copy of the record is stale).
  before_save -> { self.interview_reminded_at = nil; interview_reminded_at_will_change! }, if: :will_save_change_to_interview_at?
  # Once you apply, look for the company's public job board (Empresas-alvo).
  after_commit :find_company_board, if: -> { board_checked_at.nil? && !status_saved? && saved_change_to_status? }

  scope :in_progress, -> { where(status: OPEN_STATUSES) }
  scope :ordered, -> { order(:position, :id) }
  scope :latest_first, -> { order(Arel.sql("applied_on IS NULL, applied_on DESC"), created_at: :desc) }
  scope :upcoming_interviews, -> { in_progress.where(interview_at: Time.current..).order(:interview_at) }
  scope :follow_up_due, ->(date = Date.current) { in_progress.where(next_follow_up_on: ..date) }
  # Applied more than FOLLOW_UP_AFTER ago, still without any answer or follow-up date.
  scope :waiting_answer, ->(date = Date.current) {
    status_applied.where(applied_on: ..(date - FOLLOW_UP_AFTER), next_follow_up_on: nil)
  }

  # Interviews from 6 p.m. the day before on, still without a reminder.
  def self.interview_reminder_due(now = Time.current)
    upcoming_interviews.where(interview_reminded_at: nil).select { now >= it.interview_at.beginning_of_day - REMIND_BEFORE }
  end

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

  def interview_stage?
    INTERVIEW_STATUSES.include?(status)
  end

  def url
    contact_url.presence || job_posting&.url
  end

  private
    def set_position
      self.position = (self.class.where(status: status).maximum(:position) || -1) + 1
    end

    def find_company_board
      FindTargetCompaniesJob.perform_later
    end

    def set_responded_on
      return unless will_save_change_to_status? && RESPONSE_STATUSES.include?(status)

      self.responded_on ||= Date.current unless RESPONSE_STATUSES.include?(status_in_database)
    end

    def set_applied_on
      self.applied_on ||= Date.current if status_applied? && will_save_change_to_status?
    end
end
