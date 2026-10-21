module Sources
  # Monthly "Ask HN: Who is hiring?" thread via the Algolia API. Each top-level comment is one job.
  class HackerNews < Base
    self.key = "hacker_news"
    self.min_interval = 12.hours

    SEARCH_URL = "https://hn.algolia.com/api/v1/search_by_date?tags=story,author_whoishiring".freeze
    ITEM_URL = "https://hn.algolia.com/api/v1/items/%s".freeze
    ROLE = /engineer|developer|programmer|\bdev\b|architect|\bcto\b|desenvolvedor/i

    def self.applicable?(profile)
      profile.areas.any? { it.niche_sources.include?(key) }
    end

    def fetch
      story = HttpClient.get_json(SEARCH_URL).fetch("hits", []).find { it["title"].to_s.match?(/who is hiring/i) }
      return [] unless story

      HttpClient.get_json(format(ITEM_URL, story["objectID"])).fetch("children", []).filter_map do |comment|
        text = HtmlText.call(comment["text"])
        next unless relevant?(text) && text.match?(/\bremote\b/i)

        build(comment, text)
      end
    end

    private
      def build(comment, text)
        parts = text.lines.first.to_s.split("|").map(&:squish).compact_blank

        posting(
          title: (parts.drop(1).find { it.match?(ROLE) } || parts[1] || "Vaga no Hacker News").truncate(200),
          company: parts.first&.truncate(120),
          url: "https://news.ycombinator.com/item?id=#{comment["id"]}",
          external_id: comment["id"].to_s,
          location_text: parts.find { it.match?(/remote|onsite|on-site|hybrid/i) },
          description: text,
          posted_at: parse_time(comment["created_at"]),
          raw: { "id" => comment["id"], "author" => comment["author"] }
        )
      end
  end
end
