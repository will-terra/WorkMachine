class Consultancy < ApplicationRecord
  enum :kind, { tech: "tech", multinational: "multinational" }, validate: true

  validates :name, :url, presence: true
  validates :name, uniqueness: true

  scope :alphabetical, -> { order(:name) }

  def registered?
    registered_on.present?
  end
end
