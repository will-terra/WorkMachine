module Sources
  # Remotar (remotar.com.br): remote jobs curated for people in Brazil, read from the JSON API
  # that the site itself uses. Every job there accepts candidates from Brazil.
  class Remotar < Base
    self.key = "remotar"
    self.min_interval = 6.hours

    URL = "https://api.remotar.com.br/jobs?search=%s".freeze
    SEARCHES = %w[ruby rails].freeze

    def fetch
      jobs = SEARCHES.flat_map { |term| HttpClient.get_json(format(URL, term)).fetch("data", []) }

      jobs.uniq { it["id"] }.filter_map do |job|
        next if job["expired"] || job["active"] == false

        tags = Array(job["jobTags"]).filter_map { it.dig("tag", "name") }
        posting(
          title: job["title"],
          company: job.dig("company", "name").presence || job["companyDisplayName"],
          url: "https://remotar.com.br/job/#{job["id"]}",
          external_id: job["id"].to_s,
          location_text: job["type"] == "remote" ? "Remoto" : [ job["city"], job["state"] ].compact_blank.join(", ").presence,
          remote_scope_hint: "brazil",
          description: [ job["subtitle"], HtmlText.call(job["description"]), ("Tags: #{tags.join(", ")}" if tags.any?) ].compact_blank.join("\n\n"),
          salary_text: salary(job["jobSalary"]),
          posted_at: parse_time(job["createdAt"]),
          raw: { "id" => job["id"], "apply_url" => job["externalLink"], "tags" => tags }
        )
      end
    end

    private
      # Values come in cents.
      def salary(salary)
        return unless salary.is_a?(Hash) && salary["to"].to_i.positive?

        period = { "yearly" => "/ano", "monthly" => "/mês", "hourly" => "/hora" }[salary["type"]]
        "#{salary["currency"]} #{(salary["from"].to_i / 100).to_fs(:delimited)}–#{(salary["to"].to_i / 100).to_fs(:delimited)}#{period}"
      end
  end
end
