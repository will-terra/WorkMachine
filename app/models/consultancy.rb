class Consultancy < ApplicationRecord
  # Profiles to create once: job platforms that work by profile, and recruiting consultancies.
  enum :kind, { platform: "platform", tech: "tech", multinational: "multinational" }, validate: true

  validates :name, :url, presence: true
  validates :name, uniqueness: true

  scope :alphabetical, -> { order(:name) }

  def registered?
    registered_on.present?
  end

  # The notes of the seeded consultancies are Portuguese; config/locales has them in other languages.
  def display_notes
    I18n.t("consultancies.notes.#{name.parameterize(separator: "_")}", default: notes.to_s)
  end
end
