class Contact < ApplicationRecord
  LINKEDIN_PROFILE = %r{linkedin\.com/in/([^/?#]+)}i

  enum :kind, { recruiter: "recruiter", manager: "manager" }, validate: true

  normalizes :linkedin_url, with: ->(url) { canonical_linkedin_url(url) }

  validates :name, presence: true
  validates :linkedin_url, uniqueness: true, allow_nil: true

  scope :alphabetical, -> { order(:name) }

  # Your contacts by company (CompanyName.key), to show who you know at a job's company.
  def self.by_company
    where.not(company: [ nil, "" ]).alphabetical.group_by { CompanyName.key(it.company) }
  end

  def first_name
    name.to_s.split.first
  end

  # br.linkedin.com/in/Mariana-S/?trk=x and www.linkedin.com/in/mariana-s are the same profile.
  def self.canonical_linkedin_url(url)
    url = url.to_s.strip
    slug = url[LINKEDIN_PROFILE, 1]
    slug ? "https://www.linkedin.com/in/#{slug.downcase}" : url.presence
  end
end
