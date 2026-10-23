module Sources
  # Gupy (portal.gupy.io): the job search of the portal where Brazilian companies publish through
  # Gupy. The page brings the results as JSON (Next.js data); its robots.txt allows everything.
  # The search looks at job titles only, so each term is one search.
  class Gupy < Base
    self.key = "gupy"
    self.min_interval = 6.hours
    self.max_searches = 3

    URL = "https://portal.gupy.io/job-search/term=%s".freeze
    WORKPLACES = { "remote" => "Remoto", "hybrid" => "Híbrido", "on-site" => "Presencial" }.freeze
    CONTRACTS = { "vacancy_type_effective" => "CLT", "vacancy_legal_entity" => "PJ", "vacancy_type_internship" => "Estágio",
                  "vacancy_type_temporary" => "Temporário" }.freeze

    def fetch
      jobs = search_terms.flat_map { |term| jobs_in(HttpClient.get(format(URL, ERB::Util.url_encode(term)))) }

      jobs.uniq { it["id"] }.filter_map do |job|
        next if closed?(job) || !relevant?(job["name"], job["description"])

        posting(
          title: job["name"].squish,
          company: company(job),
          url: job["jobUrl"],
          external_id: job["id"].to_s,
          location_text: location(job),
          remote_scope_hint: "brazil",
          description: [ ("Contrato: #{CONTRACTS[job["type"]]}" if CONTRACTS[job["type"]]), HtmlText.call(job["description"]) ].compact_blank.join("\n\n"),
          posted_at: parse_time(job["publishedDate"]),
          raw: { "id" => job["id"], "type" => job["type"], "deadline" => job["applicationDeadline"], "career_page" => job["careerPageName"] }
        )
      end
    end

    private
      def jobs_in(html)
        data = Nokogiri::HTML(html).at_css("script#__NEXT_DATA__")&.text
        raise HttpClient::Error, "Gupy: a página de busca veio sem os dados das vagas" if data.blank?

        JSON.parse(data).dig("props", "pageProps", "initialJobList", "data") || []
      end

      # Old jobs stay in the search with "inactive" in the address of the career page.
      def closed?(job)
        job["jobUrl"].blank? || URI.parse(job["jobUrl"]).host.to_s.include?("inactive") ||
          job["type"] == "vacancy_type_talent_pool" || (job["applicationDeadline"].present? && parse_time(job["applicationDeadline"]) < Time.current)
      rescue URI::InvalidURIError
        true
      end

      # The name of the career page without emojis ("KOVI ❤️"), or the company it names ("Encontre aqui
      # uma vaga na Logicalis Brasil"). A hashtag slogan ("VENHA SER #SANGUELARANJA") gives way to the
      # company in the address (fcamara.gupy.io).
      def company(job)
        name = job["careerPageName"].to_s.gsub(/[\p{So}\uFE0F\u200D]/, "").squish
        name = name[/\bvagas?\s+(?:na|no|da|do|em)\s+(.+)\z/i, 1] || name
        return name if name.present? && !name.include?("#")

        URI.parse(job["jobUrl"]).host.to_s.split(".").first.to_s.capitalize.presence
      end

      def location(job)
        place = [ job["city"], job["state"] ].compact_blank.uniq.join(", ")
        [ WORKPLACES[job["workplaceType"]], place.presence ].compact.join(" · ").presence
      end
  end
end
