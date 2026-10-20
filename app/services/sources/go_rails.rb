module Sources
  # GoRails Jobs publishes an RSS feed (jobs.gorails.com/jobs.rss); every job there is Rails.
  class GoRails < Base
    self.key = "gorails"
    self.min_interval = 6.hours

    URL = "https://jobs.gorails.com/jobs.rss".freeze

    def fetch
      rss_items(HttpClient.get(URL)).map do |item|
        # Titles look like "Role - Company - Location"; the role itself may contain " - ".
        parts = item["title"].to_s.split(" - ").map(&:strip)
        title, company, location = parts.size >= 3 ? [ parts[0..-3].join(" - "), parts[-2], parts[-1] ] : [ item["title"], nil, nil ]

        posting(
          title:,
          company:,
          url: item["link"],
          external_id: item["guid"].presence || item["link"],
          location_text: location,
          description: HtmlText.call(item["description"]),
          posted_at: parse_time(item["pubDate"]),
          raw: item.slice("guid", "title")
        )
      end
    end
  end
end
