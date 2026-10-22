# A block of a routine ("Manhã", "Uma vez por semana"). The period says how long a check lasts.
class RoutineSlot < ApplicationRecord
  PERIODS = %w[daily weekly once].freeze

  enum :period, PERIODS.index_by(&:itself), prefix: true, validate: true

  belongs_to :routine
  has_many :items, -> { order(:position, :id) }, class_name: "RoutineItem", dependent: :destroy, inverse_of: :slot

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: ->(attributes) { attributes["id"].blank? && attributes["label"].blank? }

  validates :title, presence: true
end
