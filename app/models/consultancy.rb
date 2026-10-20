class Consultancy < ApplicationRecord
  # Profiles to create once: job platforms that work by profile, and recruiting consultancies.
  enum :kind, { platform: "platform", tech: "tech", multinational: "multinational" }, validate: true

  validates :name, :url, presence: true
  validates :name, uniqueness: true

  scope :alphabetical, -> { order(:name) }

  def registered?
    registered_on.present?
  end
end
