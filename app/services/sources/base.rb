module Sources
  # A job source returns posting attribute hashes ready for JobIngestor; it never writes to the database.
  class Base
    INTERVAL_TOLERANCE = 15.minutes
    RUBY_OR_RAILS = /\b(?:ruby|rails)\b/i

    class_attribute :key, instance_writer: false
    class_attribute :min_interval, instance_writer: false, default: 3.hours

    attr_reader :warnings

    def self.due?(now = Time.current)
      last = SourceRun.last_success_at(key)
      last.nil? || last <= now - min_interval + INTERVAL_TOLERANCE
    end

    def initialize
      @warnings = []
    end

    def fetch
      raise NotImplementedError
    end

    private
      def posting(**attributes)
        { source: key, **attributes }
      end

      def ruby_or_rails?(*texts)
        texts.join(" ").match?(RUBY_OR_RAILS)
      end

      def parse_time(value)
        return if value.blank?

        value.is_a?(Numeric) ? Time.zone.at(value) : Time.zone.parse(value.to_s)
      rescue ArgumentError
        nil
      end

      def rss_items(xml)
        Nokogiri::XML(xml).xpath("//item").map do |item|
          item.element_children.to_h { |child| [ child.name, child.text.strip ] }
        end
      end
  end
end
