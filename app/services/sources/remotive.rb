module Sources
  # https://github.com/remotive-com/remote-jobs-api — at most 4 calls a day, link back and credit Remotive.
  class Remotive < Base
    self.key = "remotive"
    self.min_interval = 6.hours

    URL = "https://remotive.com/api/remote-jobs?search=%s".freeze
    SEARCHES = %w[rails ruby].freeze

    def fetch
      jobs = SEARCHES.flat_map { |term| HttpClient.get_json(format(URL, term)).fetch("jobs", []) }

      jobs.uniq { it["id"] }.map do |job|
        posting(
          title: job["title"],
          company: job["company_name"],
          url: job["url"],
          external_id: job["id"].to_s,
          location_text: job["candidate_required_location"],
          description: HtmlText.call(job["description"]),
          salary_text: job["salary"].presence,
          posted_at: parse_time(job["publication_date"]),
          raw: job.slice("id", "category", "job_type", "tags")
        )
      end
    end
  end
end
