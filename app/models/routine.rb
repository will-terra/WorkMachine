# A checklist of the Rotina page (the search routine, the app setup…), made of slots ("Manhã",
# "Uma vez por semana") with items. The ready-made ones come from config/routine.yml and are copied
# to the database on first use; after that they are edited in Ajustes → Rotinas. Checks are stored
# in RoutineCheck by item key, with the profile's words in the labels.
class Routine < ApplicationRecord
  CONFIG = Rails.root.join("config/routine.yml")

  has_many :slots, -> { order(:position, :id) }, class_name: "RoutineSlot", dependent: :destroy, inverse_of: :routine
  has_many :items, through: :slots

  accepts_nested_attributes_for :slots, allow_destroy: true

  validates :name, presence: true

  scope :ordered, -> { order(:position, :id) }

  class << self
    # The routines with their slots and items, copying the ready-made ones on first use.
    def current
      ensure_defaults!
      ordered.includes(slots: :items)
    end

    def ensure_defaults!
      seed_defaults! unless Setting.current.routines_seeded_at
    end

    def seed_defaults!
      transaction do
        config.fetch("routines").each_with_index do |routine, position|
          create!(name: routine.fetch("name"), description: routine["description"], position:, slots_attributes: slots_from(routine))
        end
        Setting.current.update!(routines_seeded_at: Time.current)
      end
    end

    # Ajustes → Rotinas → Restaurar: back to config/routine.yml. Checks of the same keys are kept.
    def restore_defaults!
      transaction do
        destroy_all
        seed_defaults!
      end
    end

    def rules
      config.fetch("rules", [])
    end

    def find_item(key)
      ensure_defaults!
      RoutineItem.find_by(key: key.to_s)
    end

    # Daily items count on the day, weekly ones on the Monday of the week and "once" items forever.
    def checked_keys(date = Date.current)
      ensure_defaults!
      keys = RoutineItem.joins(:slot).pluck(:key, "routine_slots.period").group_by(&:last).transform_values { it.map(&:first) }
      RoutineCheck.where(date:, item_key: keys.fetch("daily", []))
        .or(RoutineCheck.where(date: date.beginning_of_week, item_key: keys.fetch("weekly", [])))
        .or(RoutineCheck.where(item_key: keys.fetch("once", [])))
        .pluck(:item_key).to_set
    end

    # [done, total] for the progress bar.
    def progress(checked = checked_keys)
      keys = items.map(&:key)
      [ keys.count { checked.include?(it) }, keys.size ]
    end

    # Returns true when the item ends up checked.
    def toggle!(key, date = Date.current)
      item = find_item(key) or raise ActiveRecord::RecordNotFound, "Item de rotina desconhecido: #{key}"
      checks = RoutineCheck.where(item_key: item.key)
      checks = checks.where(date: item.period_date(date)) unless item.once?

      if checks.exists?
        checks.destroy_all
        false
      else
        RoutineCheck.create!(date: item.period_date(date), item_key: item.key)
        true
      end
    end

    private
      # config/routine.yml, or its translation (config/routine.en.yml) when the interface is in English.
      def config
        localized = CONFIG.sub_ext(".#{I18n.locale}.yml")
        YAML.load_file(localized.exist? ? localized : CONFIG)
      end

      def slots_from(routine)
        routine.fetch("slots").each_with_index.map do |slot, position|
          items = slot.fetch("items").each_with_index.map { |item, index| item.slice("key", "label", "url").merge("position" => index) }
          slot.slice("title", "time").merge("period" => slot.fetch("period", "daily"), "position" => position, "items_attributes" => items)
        end
      end
  end

  # [done, total] for the progress bar.
  def progress(checked)
    keys = slots.flat_map(&:items).map(&:key)
    [ keys.count { checked.include?(it) }, keys.size ]
  end

  # Only "once" slots: a setup checklist, shown with its progress instead of every day.
  def once?
    slots.any? && slots.all?(&:period_once?)
  end
end
