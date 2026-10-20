module Sources
  # Job boards kept as GitHub issues (backend-br/vagas, frontendbr/vagas).
  # Without GITHUB_TOKEN the API allows 60 requests an hour, plenty for one call per run.
  class GithubIssues < Base
    class_attribute :repo, instance_writer: false

    URL = "https://api.github.com/repos/%s/issues?state=open&per_page=100".freeze

    def fetch
      HttpClient.get_json(format(URL, repo), headers:).filter_map do |issue|
        next if issue["pull_request"]

        labels = Array(issue["labels"]).map { it["name"] }
        next unless relevant?("#{issue["title"]} #{issue["body"]} #{labels.join(" ")}")

        build(issue, labels)
      end
    end

    private
      def relevant?(_text)
        raise NotImplementedError
      end

      def build(issue, labels)
        title = issue["title"].to_s
        location = title[/\A\s*\[([^\]]+)\]/, 1]&.squish
        clean_title = title.sub(/\A\s*\[[^\]]*\]\s*/, "").squish

        posting(
          title: clean_title.presence || title,
          company: clean_title[/\s(?:na|no|at|@)\s+([^\-–|()]+?)\s*\z/i, 1],
          url: issue["html_url"],
          external_id: issue["number"].to_s,
          location_text: location,
          remote_scope_hint: ("brazil" if location.to_s.match?(/remot/i)),
          description: issue["body"].to_s.truncate(20_000),
          posted_at: parse_time(issue["created_at"]),
          raw: { "number" => issue["number"], "labels" => labels }
        )
      end

      def headers
        token = ENV["GITHUB_TOKEN"].presence
        { "Accept" => "application/vnd.github+json" }.merge(token ? { "Authorization" => "Bearer #{token}" } : {})
      end
  end
end
