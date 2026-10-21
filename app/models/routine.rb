# Daily and weekly checklist defined in config/routine.yml, with the profile's words; checks are
# stored in RoutineCheck.
class Routine
  Slot = Data.define(:title, :time, :weekly, :items)
  Item = Data.define(:key, :label, :weekly) do
    alias_method :weekly?, :weekly
  end

  class << self
    def slots(profile = Profile.current)
      terms = SearchTerms.new(profile)
      config.fetch("slots").map do |slot|
        weekly = slot.fetch("weekly", false)
        items = slot.fetch("items").map { |item| Item.new(key: item.fetch("key"), label: terms.render_text(item.fetch("label")), weekly:) }
        Slot.new(title: slot.fetch("title"), time: slot["time"], weekly:, items:)
      end
    end

    def rules
      config.fetch("rules", [])
    end

    def items
      slots.flat_map(&:items)
    end

    def find_item(key)
      items.find { |item| item.key == key.to_s }
    end

    # Weekly items are stored on the Monday of the week, daily items on the day itself.
    def period_date(item, date)
      item.weekly? ? date.beginning_of_week : date
    end

    def checked_keys(date = Date.current)
      daily, weekly = items.partition { |item| !item.weekly? }
      RoutineCheck.where(date: date, item_key: daily.map(&:key))
        .or(RoutineCheck.where(date: date.beginning_of_week, item_key: weekly.map(&:key)))
        .pluck(:item_key).to_set
    end

    # Returns true when the item ends up checked.
    def toggle!(key, date = Date.current)
      item = find_item(key) or raise ActiveRecord::RecordNotFound, "Item de rotina desconhecido: #{key}"
      check = RoutineCheck.find_by(date: period_date(item, date), item_key: item.key)

      if check
        check.destroy!
        false
      else
        RoutineCheck.create!(date: period_date(item, date), item_key: item.key)
        true
      end
    end

    private
      def config
        YAML.load_file(Rails.root.join("config/routine.yml"))
      end
  end
end
