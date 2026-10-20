class RoutineCheck < ApplicationRecord
  validates :date, :item_key, presence: true
  validates :item_key, uniqueness: { scope: :date }
end
