module Sources
  # https://remoteok.com/api — needs a User-Agent; the terms ask for a link back and credit to Remote OK.
  class RemoteOk < Base
    self.key = "remote_ok"

    URL = "https://remoteok.com/api".freeze
    TAGS = /\A(?:ruby|rails|ruby on rails|ror)\z/i

    def fetch
      HttpClient.get_json(URL).filter_map do |job|
        next unless job.is_a?(Hash) && job["position"] && Array(job["tags"]).any? { it.to_s.match?(TAGS) }

        posting(
          title: job["position"],
          company: job["company"],
          url: job["url"],
          external_id: job["id"].to_s,
          location_text: job["location"].presence,
          description: HtmlText.call(job["description"]),
          salary_text: salary(job),
          posted_at: parse_time(job["date"]),
          raw: job.slice("id", "tags", "salary_min", "salary_max")
        )
      end
    end

    private
      def salary(job)
        min, max = job.values_at("salary_min", "salary_max").map(&:to_i)
        return if max.zero?

        "US$ #{min.to_fs(:delimited)}–#{max.to_fs(:delimited)}/ano"
      end
  end
end
