module Sources
  # https://himalayas.app/jobs/api — public remote-jobs API; search results come 20 per page.
  class Himalayas < Base
    self.key = "himalayas"
    self.min_interval = 6.hours
    self.max_searches = 3

    URL = "https://himalayas.app/jobs/api/search?q=%s&page=%d".freeze
    PAGES = 2

    def fetch
      jobs = search_terms.product((1..PAGES).to_a).flat_map do |term, page|
        HttpClient.get_json(format(URL, ERB::Util.url_encode(term), page)).fetch("jobs", [])
      end

      jobs.uniq { it["guid"] }.filter_map do |job|
        description = HtmlText.call(job["description"].presence || job["excerpt"])
        next unless relevant?(job["title"], description)

        posting(
          title: job["title"],
          company: job["companyName"],
          url: job["guid"].presence || job["applicationLink"],
          external_id: job["guid"],
          location_text: Array(job["locationRestrictions"]).join(", ").presence || "Anywhere",
          description:,
          salary_text: salary(job),
          posted_at: parse_time(job["pubDate"].to_i),
          raw: job.slice("companySlug", "seniority", "timezoneRestrictions", "employmentType")
        )
      end
    end

    private
      def salary(job)
        return unless job["maxSalary"].to_i.positive?

        "#{job["currency"]} #{job["minSalary"].to_i.to_fs(:delimited)}–#{job["maxSalary"].to_i.to_fs(:delimited)} #{job["salaryPeriod"]}".squish
      end
  end
end
