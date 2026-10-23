# The manual tasks of config/radar.yml (what the app cannot fetch by itself, by frequency), with
# the searches filled in from the profile, the summary of the automated sources, and the URL
# builders that turn a query and the chosen filters into a ready-to-open search.
class Radar
  LINKEDIN_REGIONS = {
    "br_remote" => "&geoId=106057199&f_WT=2",
    "world_remote" => "&geoId=92000000&f_WT=2",
    "br_all" => "&geoId=106057199"
  }.freeze
  BUILDERS = %w[li_jobs li_jobs_world li_posts li_people_br li_people google google_jobs x].freeze
  # Screens of the app that config/radar.yml may link to ("app_link").
  APP_LINKS = { "target_companies" => :target_companies_path, "job_postings" => :job_postings_path,
                "job_applications" => :job_applications_path }.freeze

  # A source the app already fetches by itself, with the result of its latest run. "off" when its
  # sources are turned off in Ajustes or do not match the profile.
  Automated = Data.define(:name, :url, :app_link, :note, :sources, :interval, :last_run_at, :failed, :fetched_count, :created_count,
                          :error_message, :off) do
    def needs_gmail? = (sources & %w[linkedin_alert application_replies]).any?
  end

  class << self
    # config/radar.yml with the texts of config/radar.<locale>.yml on top, when there is one.
    def config
      base = YAML.load_file(Rails.root.join("config/radar.yml"))
      localized = Rails.root.join("config/radar.#{I18n.locale}.yml")
      localized.exist? ? translate(base, YAML.load_file(localized)) : base
    end

    def tasks
      config.fetch("tasks")
    end

    # The tasks with the profile's words: searches filled in (or replaced by the profile's own
    # query), searches and links that do not apply left out, and the texts rendered.
    def tasks_for(profile = Profile.current)
      terms = SearchTerms.new(profile)

      tasks.map do |task|
        task.merge(
          "action" => terms.render_text(task["action"]),
          "more" => task["more"] && terms.render_text(task["more"]),
          "searches" => task.fetch("searches", []).filter_map { render_search(it, profile, terms) },
          "links" => task.fetch("links", []).filter_map { render_link(it, profile, terms) }
        )
      end
    end

    def searches_for(profile = Profile.current)
      tasks_for(profile).flat_map { it["searches"] }
    end

    # The searches with the "ativado" box (Alertas do LinkedIn), filled in from the profile.
    def alert_searches(profile = Profile.current)
      tasks_for(profile).select { it["checkable"] }.flat_map { it["searches"] }
    end

    # How many of them are left to turn on (none while the profile is empty).
    def pending_alerts(profile = Profile.current)
      profile.configured? ? ActivatedAlert.pending_count(alert_searches(profile)) : 0
    end

    # Terms to fill in the profiles of platforms and consultancies (Cadastros).
    def profile_keywords(profile = Profile.current)
      {
        "titles" => profile.target_titles + profile.target_titles_en,
        "skills" => (profile.skills_at("essential") + profile.skills_at("important")).map { it["name"] },
        "plan_b" => profile.plan_b_terms
      }
    end

    def cadences
      config.fetch("cadences")
    end

    def filters
      config.fetch("filters")
    end

    def searches
      tasks.flat_map { |task| task.fetch("searches", []) }
    end

    def automated(runs = SourceRun.latest_per_source.index_by(&:source), profile: Profile.current, setting: Setting.current)
      terms = SearchTerms.new(profile)
      enabled = Sources.enabled(profile, setting).map(&:key)
      config.fetch("automated").map do |entry|
        keys = entry.fetch("sources")
        latest = runs.values_at(*keys).compact
        Automated.new(
          name: entry.fetch("name"),
          url: entry["url"],
          app_link: APP_LINKS.fetch(entry["app_link"], nil),
          note: terms.render_text(entry["note"]),
          sources: keys,
          interval: interval_for(keys.first),
          last_run_at: latest.map(&:created_at).max,
          failed: latest.any?(&:status_failed?),
          fetched_count: latest.sum(&:fetched_count),
          created_count: latest.sum(&:created_count),
          error_message: latest.filter_map { it.error_message.presence }.first,
          off: keys.all? { Sources.find(it) && !enabled.include?(it) }
        )
      end
    end

    # LinkedIn alerts are imported every hour; the aggregator runs every 3 hours and each
    # source may ask for a longer interval (Sources::Base.min_interval).
    def interval_for(source_key)
      return 1.hour if source_key.in?(%w[linkedin_alert application_replies])

      [ Sources.find(source_key)&.min_interval || 3.hours, 3.hours ].max
    end

    # Only texts are taken from the translation: queries, builders and URLs come from radar.yml.
    def translate(base, texts)
      base.fetch("automated").each { it.merge!(texts.dig("automated", it["name"]).to_h.slice("name", "note")) }
      base.fetch("cadences").each { it.merge!(texts.dig("cadences", it["key"]).to_h.slice("title", "time")) }
      base.fetch("filters").each do |name, filter|
        filter["label"] = texts.dig("filters", name, "label") || filter["label"]
        filter.fetch("options").each { |option| option["label"] = texts.dig("filters", name, "options", option["value"].to_s) || option["label"] }
      end
      base.fetch("tasks").each do |task|
        task.merge!(texts.dig("tasks", task["key"]).to_h.slice("title", "action", "more"))
        task["link"] = task["link"].merge(texts.dig("tasks", task["key"], "link").to_h.slice("label")) if task["link"]
        task.fetch("searches", []).each { it.merge!(texts.dig("searches", it["key"]).to_h.slice("title", "note")) }
        task.fetch("links", []).each { it.merge!(texts.dig("links", it["name"]).to_h.slice("name", "note")) }
      end
      base
    end

    def default_filters
      filters.transform_values { |filter| filter.fetch("default") }
    end

    # Keeps only known filter values; anything else falls back to the default.
    def sanitize_filters(values)
      values = values.to_h.stringify_keys
      filters.to_h do |name, filter|
        allowed = filter.fetch("options").map { |option| option.fetch("value").to_s }
        [ name, allowed.include?(values[name].to_s) ? values[name].to_s : filter.fetch("default").to_s ]
      end
    end

    # "local" (Perto de você) searches around the profile's location; without one, all of Brazil.
    def url_for(builder, query, filters = default_filters, location: nil)
      q = ERB::Util.url_encode(query)

      case builder
      when "li_jobs", "li_jobs_world"
        region = builder == "li_jobs_world" ? "world_remote" : filters.fetch("li_region")
        "https://www.linkedin.com/jobs/search/?keywords=#{q}#{linkedin_region(region, location)}&f_TPR=#{filters.fetch("li_period")}&sortBy=DD"
      when "li_posts"
        "https://www.linkedin.com/search/results/content/?keywords=#{q}&datePosted=#{ERB::Util.url_encode(%("#{filters.fetch("post_period")}"))}&sortBy=#{ERB::Util.url_encode('"date_posted"')}"
      when "li_people_br"
        "https://www.linkedin.com/search/results/people/?keywords=#{q}&geoUrn=#{ERB::Util.url_encode('["106057199"]')}"
      when "li_people"
        "https://www.linkedin.com/search/results/people/?keywords=#{q}"
      when "google"
        period = filters.fetch("g_period")
        "https://www.google.com/search?q=#{q}#{"&tbs=qdr:#{period}" if period.present?}"
      when "google_jobs"
        "https://www.google.com/search?q=#{q}&ibp=htl;jobs"
      when "x"
        "https://x.com/search?q=#{q}&src=typed_query&f=live"
      else
        raise ArgumentError, "Builder desconhecido: #{builder}"
      end
    end

    private
      def render_search(search, profile, terms)
        template = search.fetch("query")
        query = terms.render(profile.search_overrides[search["key"]].presence || template)
        search.merge("query" => query, "template" => template, "custom" => profile.search_overrides.key?(search["key"])) if query
      end

      def render_link(link, profile, terms)
        return if link["only_for"] && !profile.mentions?(link["only_for"])

        url = terms.render(link["url"], url: true) or return
        link.merge("url" => url)
      end

      def linkedin_region(region, location)
        return LINKEDIN_REGIONS.fetch(region) unless region == "local"

        location.present? ? "&location=#{ERB::Util.url_encode(location)}" : LINKEDIN_REGIONS.fetch("br_all")
      end
  end
end
