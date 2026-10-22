# A task of a routine. The key ties it to its checks (RoutineCheck); the ready-made items keep the
# keys of config/routine.yml and new ones get a random key.
class RoutineItem < ApplicationRecord
  belongs_to :slot, class_name: "RoutineSlot", foreign_key: :routine_slot_id, inverse_of: :items

  normalizes :label, with: ->(value) { value.strip }
  normalizes :url, with: ->(value) { value.strip.presence }

  before_validation -> { self.key ||= "i#{SecureRandom.hex(4)}" }, on: :create

  validates :label, presence: true
  validates :key, presence: true, uniqueness: true
  validates :url, format: { with: %r{\A(?:/|https?://)\S*\z} }, allow_nil: true

  def weekly?
    slot.period_weekly?
  end

  def once?
    slot.period_once?
  end

  # The date its check is stored on: the Monday of the week for weekly items, else the day.
  def period_date(date)
    weekly? ? date.beginning_of_week : date
  end
end
