class JobPosting < ApplicationRecord
  SOURCES = %w[remotive remote_ok we_work_remotely backend_br frontend_br hacker_news
               greenhouse lever ashby linkedin_alert extension manual].freeze
  REMOTE_SCOPES = %w[brazil latam worldwide us_only europe_only unknown].freeze
  SENIORITIES = %w[junior mid senior unknown].freeze
  TRIAGES = %w[new saved dismissed].freeze

  enum :source, SOURCES.index_by(&:itself), validate: true
  enum :remote_scope, REMOTE_SCOPES.index_by(&:itself), prefix: :remote, validate: true
  enum :seniority, SENIORITIES.index_by(&:itself), prefix: true, validate: true
  enum :triage, TRIAGES.index_by(&:itself), prefix: true, validate: true

  has_one :job_application, dependent: :nullify
  has_many :ai_artifacts, dependent: :destroy

  normalizes :url, with: ->(url) { UrlNormalizer.call(url) }
  normalizes :title, :company, with: ->(value) { value.to_s.squish.presence }

  before_validation :set_fingerprint

  validates :title, :url, :fingerprint, presence: true
  validates :url, uniqueness: true
  validates :score, numericality: { in: 0..100 }

  scope :ranked, -> { order(score: :desc, posted_at: :desc, id: :desc) }
  scope :recent, -> { order(Arel.sql("COALESCE(posted_at, created_at) DESC")) }

  def self.fingerprint_for(company, title)
    [ company, title ].map { |part| I18n.transliterate(part.to_s.downcase).gsub(/[^a-z0-9]+/, " ").squish }.join("|")
  end

  # Finds an existing posting for the same job: same normalized URL, or same company + title.
  def self.find_duplicate(url:, company:, title:)
    find_by(url: UrlNormalizer.call(url)) ||
      (find_by(fingerprint: fingerprint_for(company, title)) if company.present?)
  end

  def display_company
    company.presence || "Empresa não informada"
  end

  def posted_or_found_at
    posted_at || created_at
  end

  private
    def set_fingerprint
      self.fingerprint = self.class.fingerprint_for(company, title)
    end
end
