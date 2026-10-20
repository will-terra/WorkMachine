module Sources
  # Public job widget of Workable accounts (apply.workable.com/<slug>).
  class Workable < AtsBoard
    self.key = "workable"

    URL = "https://apply.workable.com/api/v1/widget/accounts/%s?details=true".freeze

    private
      def fetch_company(company)
        HttpClient.get_json(format(URL, company.board_slug)).fetch("jobs", []).map do |job|
          place = [ job["city"], job["state"], job["country"] ].compact_blank.join(", ")
          posting(
            title: job["title"],
            company: company.name,
            url: job["url"],
            external_id: job["shortcode"],
            location_text: [ (job["telecommuting"] ? "Remote" : nil), place.presence ].compact.join(" · ").presence,
            description: HtmlText.call(job["description"]),
            posted_at: parse_time(job["published_on"] || job["created_at"]),
            raw: { "shortcode" => job["shortcode"], "board" => company.board_slug }
          )
        end
      end
  end
end
