module Sources
  # Public RSS feeds of We Work Remotely, filtered by "ruby"/"rails" in the title or description text.
  class WeWorkRemotely < Base
    self.key = "we_work_remotely"

    FEEDS = %w[
      https://weworkremotely.com/categories/remote-full-stack-programming-jobs.rss
      https://weworkremotely.com/categories/remote-back-end-programming-jobs.rss
    ].freeze

    def fetch
      FEEDS.flat_map { |feed| rss_items(HttpClient.get(feed)) }.uniq { it["guid"] }.filter_map do |item|
        description = HtmlText.call(item["description"])
        next unless ruby_or_rails?(item["title"], description)

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
