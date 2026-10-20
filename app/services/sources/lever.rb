module Sources
  # https://github.com/lever/postings-api
  class Lever < AtsBoard
    self.key = "lever"

    URL = "https://api.lever.co/v0/postings/%s?mode=json".freeze

    private
      def fetch_company(company)
        HttpClient.get_json(format(URL, company.board_slug)).map do |job|
          posting(
            title: job["text"],
            company: company.name,
            url: job["hostedUrl"],
            external_id: job["id"],
            location_text: [ job.dig("categories", "location"), job["workplaceType"] ].compact_blank.join(" · ").presence,
            description: description(job),
            salary_text: salary(job["salaryRange"]),
            posted_at: parse_time(job["createdAt"].to_i / 1000.0),
            raw: { "id" => job["id"], "board" => company.board_slug, "categories" => job["categories"] }
          )
        end
      end

      def description(job)
        lists = Array(job["lists"]).map { |list| "#{list["text"]}\n#{HtmlText.call(list["content"])}" }
        [ job["descriptionPlain"], *lists, job["additionalPlain"] ].compact_blank.join("\n\n")
      end

      def salary(range)
        return unless range.is_a?(Hash) && range["max"].to_i.positive?

        "#{range["currency"]} #{range["min"].to_i.to_fs(:delimited)}–#{range["max"].to_i.to_fs(:delimited)} #{range["interval"]}".squish
      end
  end
end
