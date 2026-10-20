module Sources
  # https://www.workingnomads.com/api/exposed_jobs/ — public feed of the latest remote jobs.
  # Kept only when the title or the tags mention Ruby or Rails (descriptions list many stacks).
  class WorkingNomads < Base
    self.key = "working_nomads"

    URL = "https://www.workingnomads.com/api/exposed_jobs/".freeze

    def fetch
      HttpClient.get_json(URL).filter_map do |job|
        next unless ruby_or_rails?(job["title"], job["tags"].to_s.tr(",", " "))

        posting(
          title: job["title"],
          company: job["company_name"],
          url: job["url"],
          external_id: job["url"],
          location_text: job["location"].presence,
          description: HtmlText.call(job["description"]),
          posted_at: parse_time(job["pub_date"]),
          raw: job.slice("category_name", "tags")
        )
      end
    end
  end
end
