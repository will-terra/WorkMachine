module Sources
  # https://developers.greenhouse.io/job-board.html
  class Greenhouse < AtsBoard
    self.key = "greenhouse"

    URL = "https://boards-api.greenhouse.io/v1/boards/%s/jobs?content=true".freeze

    private
      def fetch_company(company)
        HttpClient.get_json(format(URL, company.board_slug)).fetch("jobs", []).map do |job|
          posting(
            title: job["title"],
            company: job["company_name"].presence || company.name,
            url: job["absolute_url"],
            external_id: job["id"].to_s,
            location_text: job.dig("location", "name"),
            description: HtmlText.call(CGI.unescapeHTML(job["content"].to_s)),
            posted_at: parse_time(job["first_published"] || job["updated_at"]),
            raw: { "id" => job["id"], "board" => company.board_slug }
          )
        end
      end
  end
end
