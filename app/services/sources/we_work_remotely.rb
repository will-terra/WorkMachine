module Sources
  # Public RSS feeds of We Work Remotely for the profile's area, filtered by the search terms in
  # the title or the description.
  class WeWorkRemotely < Base
    self.key = "we_work_remotely"

    FEED_URL = "https://weworkremotely.com/categories/%s.rss".freeze
    DEFAULT_FEEDS = %w[remote-full-stack-programming-jobs remote-back-end-programming-jobs].freeze

    def self.feeds(profile)
      (profile.primary_area_record&.wwr_feeds.presence || DEFAULT_FEEDS).map { format(FEED_URL, it) }
    end

    def fetch
      self.class.feeds(profile).flat_map { |feed| rss_items(HttpClient.get(feed)) }.uniq { it["guid"] }.filter_map do |item|
        description = HtmlText.call(item["description"])
        next unless relevant?(item["title"], description)

        company, title = item["title"].to_s.split(": ", 2)
        title, company = company, nil if title.blank?

        posting(
          title:,
          company:,
          url: item["link"],
          external_id: item["guid"],
          location_text: [ item["region"], item["country"] ].compact_blank.join(" · ").presence,
          description:,
          posted_at: parse_time(item["pubDate"]),
          raw: item.slice("guid", "region", "country", "skills", "type")
        )
      end
    end
  end
end
