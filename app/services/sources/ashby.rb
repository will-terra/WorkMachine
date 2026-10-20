module Sources
  # https://developers.ashbyhq.com/docs/public-job-posting-api
  class Ashby < AtsBoard
    self.key = "ashby"

    URL = "https://api.ashbyhq.com/posting-api/job-board/%s?includeCompensation=true".freeze

    private
      def fetch_company(company)
        HttpClient.get_json(format(URL, company.board_slug)).fetch("jobs", []).filter_map do |job|
          next if job["isListed"] == false

          posting(
            title: job["title"],
            company: company.name,
            url: job["jobUrl"],
            external_id: job["id"],
            location_text: [ job["location"], job.dig("address", "postalAddress", "addressCountry") ].compact_blank.uniq.join(" · ").presence,
            description: job["descriptionPlain"].presence || HtmlText.call(job["descriptionHtml"]),
            salary_text: job.dig("compensation", "compensationTierSummary"),
            posted_at: parse_time(job["publishedAt"]),
            raw: { "id" => job["id"], "board" => company.board_slug, "workplaceType" => job["workplaceType"] }
          )
        end
      end
  end
end
