class TargetCompany < ApplicationRecord
  BOARD_URLS = {
    "greenhouse" => "https://job-boards.greenhouse.io/%s",
    "lever" => "https://jobs.lever.co/%s",
    "ashby" => "https://jobs.ashbyhq.com/%s"
  }.freeze

  enum :ats, BOARD_URLS.keys.index_by(&:itself), validate: true

  normalizes :board_slug, with: ->(slug) { slug.strip.downcase }

  validates :name, :board_slug, presence: true
  validates :board_slug, format: { with: /\A[a-z0-9][a-z0-9._-]*\z/ }, uniqueness: { scope: :ats }

  scope :active, -> { where(active: true) }
  scope :alphabetical, -> { order(:name) }

  def board_url
    format(BOARD_URLS.fetch(ats), board_slug)
  end
end
