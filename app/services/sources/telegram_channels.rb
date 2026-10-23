module Sources
  # Public Telegram channels of jobs, read from their web preview (t.me/s/<channel>), which needs
  # no login. Groups have no preview, so the ones listed in the Radar stay by hand. Each post
  # starts with hashtag lines (area, level, place) and then the title; posts without hashtags are
  # notices of the channel. The one channel today is for beginners, so the source only runs for a
  # junior profile.
  class TelegramChannels < Base
    self.key = "telegram"
    self.min_interval = 6.hours

    CHANNELS = %w[CafeinaVagas].freeze
    URL = "https://t.me/s/%s".freeze
    # "💻 #dev", "🌎 #remoto ou #hibrido #SP" (not "C#" in a title, nor a "### heading").
    TAG_LINE = /\A[^\p{L}\p{N}#]*#[\p{L}\p{N}]/

    def self.applicable?(profile)
      profile.seniority == "junior"
    end

    def fetch
      CHANNELS.flat_map do |channel|
        Nokogiri::HTML(HttpClient.get(format(URL, channel))).css(".tgme_widget_message[data-post]").filter_map { post(it) }
      end
    end

    private
      def post(node)
        body = node.at_css(".tgme_widget_message_text") or return
        lines = text_of(body).lines.map(&:squish).compact_blank
        tags, rest = lines.partition { it.match?(TAG_LINE) }
        title = rest.reject { it.start_with?("💰") }.map { clean(it) }.find(&:present?)
        return if tags.empty? || title.blank? || !relevant?(lines.join("\n"))

        links = body.css("a[href^='http']").map { it["href"] }.grep_v(%r{\Ahttps?://(?:[\w-]+\.)*t\.me(?:/|\z)})
        place = tags.find { it.match?(/#(?:remoto|hibrido|híbrido|presencial)/i) }
        posting(
          title:,
          company: title[/\s[-–]\s([^-–]*\p{L}[^-–]*)\z/, 1]&.squish,
          url: "https://t.me/#{node["data-post"]}",
          external_id: node["data-post"],
          location_text: place&.delete("#")&.gsub(/\A\W+/, "")&.squish,
          remote_scope_hint: "brazil",
          description: lines.join("\n"),
          salary_text: lines.find { it.start_with?("💰") }&.delete_prefix("💰")&.squish,
          posted_at: parse_time(node.at_css("time[datetime]")&.[]("datetime")),
          raw: { "post" => node["data-post"], "apply_url" => links.first, "tags" => tags.flat_map { it.scan(/#([\p{L}\p{N}_]+)/).flatten } }
        )
      end

      def text_of(body)
        body = body.dup
        body.css("br").each { it.replace("\n") }
        body.text
      end

      # "💻 Desenvolvedor\(a\) Front-end Júnior" → "Desenvolvedor(a) Front-end Júnior"; "### Sobre a vaga" is a heading.
      def clean(line)
        return "" if line.start_with?("#")

        line.gsub(/\\([()\[\]_*.!-])/, '\1').sub(/\A[^\p{L}\p{N}]+/, "").squish
      end
  end
end
