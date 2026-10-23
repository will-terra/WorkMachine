module Sources
  # Vagas.com (vagas.com.br): the search pages by term (/vagas-de-ruby) come with the jobs in the
  # HTML. robots.txt closes /vagas/pesquisas and the API, not these pages. Few niche stacks there,
  # more corporate and broad roles.
  class VagasCom < Base
    self.key = "vagas_com"
    self.min_interval = 12.hours
    self.max_searches = 3

    BASE = "https://www.vagas.com.br".freeze
    URL = "#{BASE}/vagas-de-%s".freeze

    def fetch
      jobs = search_terms.map { it.to_s.parameterize }.compact_blank.uniq.flat_map do |slug|
        Nokogiri::HTML(HttpClient.get(format(URL, slug))).css("li.vaga").filter_map { job(it) }
      end

      jobs.uniq { it[:external_id] }.filter_map do |job|
        next unless relevant?(job[:title], job[:description])

        posting(**job, remote_scope_hint: "brazil")
      end
    end

    private
      def job(node)
        link = node.at_css("a.link-detalhes-vaga") or return
        level = node.at_css(".nivelVaga")&.text&.squish

        {
          title: (link["title"].presence || link.text).squish,
          company: node.at_css(".emprVaga")&.text&.squish.presence,
          url: URI.join(BASE, link["href"]).to_s.sub(/\?.*\z/, ""),
          external_id: link["data-id-vaga"].presence || link["href"][%r{/vagas/v(\d+)}, 1],
          location_text: node.at_css(".vaga-local")&.text&.squish.presence,
          description: [ node.at_css(".detalhes")&.text&.squish&.delete_prefix("Descrição:")&.strip, ("Nível: #{level}" if level.present?) ].compact_blank.join("\n\n"),
          posted_at: date(node.at_css(".data-publicacao")&.text),
          raw: { "level" => level }
        }
      end

      # "24/09/2026"; recent jobs may say "Hoje" or "Ontem".
      def date(text)
        text = text.to_s.squish
        return Time.current.beginning_of_day if text.match?(/\Ahoje\z/i)
        return 1.day.ago.beginning_of_day if text.match?(/\Aontem\z/i)

        Time.zone.strptime(text, "%d/%m/%Y") if text.match?(%r{\A\d{2}/\d{2}/\d{4}\z})
      rescue ArgumentError
        nil
      end
  end
end
