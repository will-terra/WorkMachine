class Contact < ApplicationRecord
  enum :kind, { recruiter: "recruiter", manager: "manager" }, validate: true

  normalizes :linkedin_url, with: ->(url) { url.strip.presence }

  validates :name, presence: true
  validates :linkedin_url, uniqueness: true, allow_nil: true

  scope :alphabetical, -> { order(:name) }
end
