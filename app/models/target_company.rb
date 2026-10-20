class TargetCompany < ApplicationRecord
  BOARD_URLS = {
    "greenhouse" => "https://job-boards.greenhouse.io/%s",
    "lever" => "https://jobs.lever.co/%s",
    "ashby" => "https://jobs.ashbyhq.com/%s",
    "workable" => "https://apply.workable.com/%s"
  }.freeze

  enum :ats, BOARD_URLS.keys.index_by(&:itself), validate: true

  normalizes :board_slug, with: ->(slug) { slug.strip.downcase }

  validates :name, :board_slug, presence: true
  validates :board_slug, format: { with: /\A[a-z0-9][a-z0-9._-]*\z/ }, uniqueness: { scope: :ats }

  belongs_to :discovered_from, class_name: "JobPosting", optional: true

  scope :active, -> { where(active: true) }
  scope :suggested, -> { where(active: false).where.not(discovered_at: nil) }
  scope :alphabetical, -> { order(:name) }

  # Postings each board brought, saved and auto-dismissed: { [ats, slug] => { total:, saved:, auto_dismissed: } }.
  def self.posting_stats
    board = Arel.sql("json_extract(raw, '$.board')")
    scope = JobPosting.where(source: ats.keys)
    total = scope.group(:source, board).count
    saved = scope.triage_saved.group(:source, board).count
    auto = scope.where.not(auto_dismissed_reason: nil).group(:source, board).count
    total.to_h { |key, count| [ key, { total: count, saved: saved.fetch(key, 0), auto_dismissed: auto.fetch(key, 0) } ] }
  end

  def board_url
    format(BOARD_URLS.fetch(ats), board_slug)
  end
end
