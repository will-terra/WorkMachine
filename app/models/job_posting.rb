class JobPosting < ApplicationRecord
  SOURCES = %w[remotive remote_ok we_work_remotely working_nomads himalayas remotar backend_br frontend_br
               hacker_news gorails greenhouse lever ashby workable linkedin_alert extension manual].freeze
  REMOTE_SCOPES = %w[brazil latam worldwide us_only europe_only unknown].freeze
  SENIORITIES = %w[junior mid senior unknown].freeze
  TRIAGES = %w[new saved dismissed].freeze
  # Saved by Ana himself: never dismissed automatically.
  MANUAL_SOURCES = %w[extension manual].freeze

  enum :source, SOURCES.index_by(&:itself), validate: true
  enum :remote_scope, REMOTE_SCOPES.index_by(&:itself), prefix: :remote, validate: true
  enum :seniority, SENIORITIES.index_by(&:itself), prefix: true, validate: true
  enum :triage, TRIAGES.index_by(&:itself), prefix: true, validate: true

  has_one :job_application, dependent: :nullify
  has_many :ai_artifacts, dependent: :destroy
  has_many :discovered_target_companies, class_name: "TargetCompany", foreign_key: :discovered_from_id,
                                         inverse_of: :discovered_from, dependent: :nullify

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

  def rescore!
    result = JobScorer.call(title:, description:, location_text:, remote_scope_hint:)
    update!(score: result.score, matched_keywords: result.matched_keywords,
            remote_scope: result.remote_scope, seniority: result.seniority)
  end

  # Region given by the source itself (Remotar, "[Remoto]" on backend-br), kept in raw.
  def remote_scope_hint
    raw["remote_scope_hint"].presence || legacy_remote_scope_hint
  end

  # Without a description (LinkedIn alert e-mails), the score only sees the title and the location.
  def partial_score?
    description.blank?
  end

  def display_company
    company.presence || "Empresa não informada"
  end

  def posted_or_found_at
    posted_at || created_at
  end

  private
    # Postings saved before the hint was kept in raw.
    def legacy_remote_scope_hint
      return "brazil" if remotar?

      "brazil" if (backend_br? || frontend_br?) && location_text.to_s.match?(/remot/i)
    end

    def set_fingerprint
      self.fingerprint = self.class.fingerprint_for(company, title)
    end
end
