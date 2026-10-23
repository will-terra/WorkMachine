module Sources
  # Programathor (programathor.com.br): Brazilian tech jobs, one page per technology
  # (/jobs-ruby, /jobs-react). The site ignores free-text search, so each term of the profile is
  # a technology page (every card there carries that technology); an unknown technology answers
  # 404 and is skipped. Expired jobs stay on the page marked "Vencida". robots.txt only closes the
  # account pages.
  class Programathor < Base
    self.key = "programathor"
    self.min_interval = 12.hours
    self.max_searches = 3

    BASE = "https://programathor.com.br".freeze
    URL = "#{BASE}/jobs-%s".freeze
    # The icons in front of each detail of the card.
    DETAILS = { "fa-briefcase" => :company, "fa-map-marker-alt" => :location, "fa-money-bill-alt" => :salary,
                "fa-chart-bar" => :level, "fa-file-alt" => :contract, "fa-building" => :size }.freeze

    def fetch
      cards = search_terms.map { it.to_s.parameterize }.compact_blank.uniq.flat_map { |slug| cards_for(slug) }

      cards.uniq { it[:url] }.filter_map do |card|
        next if card[:expired]

        posting(
          title: card[:title],
          company: card[:company],
          url: card[:url],
          external_id: card[:url][%r{/jobs/(\d+)}, 1],
          location_text: card[:location],
          remote_scope_hint: ("brazil" if card[:location].to_s.match?(/\Aremoto\z/i)),
          description: [ ("Tecnologias: #{card[:tags].join(", ")}" if card[:tags].any?),
                         [ card[:level], card[:contract], card[:size] ].compact.join(" · ").presence ].compact.join("\n"),
          salary_text: card[:salary],
          raw: card.slice(:tags, :level, :contract)
        )
      end
    end

    private
      def cards_for(slug)
        Nokogiri::HTML(HttpClient.get(format(URL, slug))).css("div.cell-list").filter_map { card(it) }
      rescue HttpClient::Error => e
        raise unless e.status == 404

        []
      end

      def card(node)
        link = node.at_css("a[href^='/jobs/']") or return
        title = node.at_css("h3") or return
        details = node.css(".cell-list-content-icon > span").to_h do |detail|
          icon = detail.at_css("i")&.[]("class").to_s.split.find { DETAILS.key?(it) }
          [ DETAILS[icon], detail.text.squish ]
        end.except(nil)

        {
          title: title.children.reject { it.name == "span" }.map(&:text).join.squish,
          expired: title.text.include?("Vencida") || node["class"].to_s.include?("opacity-60p"),
          url: "#{BASE}#{link["href"]}",
          tags: node.css(".tag-list").map { it.text.squish },
          **details
        }
      end
  end
end
