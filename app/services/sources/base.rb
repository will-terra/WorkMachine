module Sources
  # A job source returns posting attribute hashes ready for JobIngestor; it never writes to the database.
  # What it searches for and keeps comes from the profile (search terms, areas).
  class Base
    INTERVAL_TOLERANCE = 15.minutes

    class_attribute :key, instance_writer: false
    class_attribute :min_interval, instance_writer: false, default: 3.hours
    # Term searches per run, so the APIs' limits hold with any profile.
    class_attribute :max_searches, instance_writer: false, default: 2

    attr_reader :warnings, :profile

    def self.due?(now = Time.current)
      last = SourceRun.last_success_at(key)
      last.nil? || last <= now - min_interval + INTERVAL_TOLERANCE
    end

    # Niche sources (GoRails, backend-br…) only make sense for some profiles.
    def self.applicable?(_profile)
      true
    end

    def initialize(profile = Profile.current)
      @profile = profile
      @warnings = []
    end

    def fetch
      raise NotImplementedError
    end

    private
      def posting(**attributes)
        { source: key, **attributes }
      end

      def relevant?(*texts)
        profile.relevant?(*texts)
      end

      def search_terms
        profile.effective_search_terms.first(max_searches)
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
