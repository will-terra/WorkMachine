# Searches and places from config/radar.yml (ported from docs/radar-vagas-rails.html),
# plus the URL builders that turn a query and the chosen filters into a ready-to-open search.
class Radar
  LINKEDIN_REGIONS = {
    "br_remote" => "&geoId=106057199&f_WT=2",
    "world_remote" => "&geoId=92000000&f_WT=2",
    "rs" => "&location=#{ERB::Util.url_encode("Paraná, Brasil")}",
    "br_all" => "&geoId=106057199"
  }.freeze
  BUILDERS = %w[li_jobs li_jobs_world li_posts li_people_br li_people google google_jobs x].freeze
  # Screens of the app that config/radar.yml may link to ("app_link").
  APP_LINKS = { "target_companies" => :target_companies_path, "job_postings" => :job_postings_path }.freeze

  # A source the app already fetches by itself, with the result of its latest run.
  Automated = Data.define(:name, :url, :app_link, :note, :sources, :interval, :last_run_at, :failed, :created_count, :error_message) do
    def needs_gmail? = sources == [ "linkedin_alert" ]
  end

  class << self
    def config
      YAML.load_file(Rails.root.join("config/radar.yml"))
    end

    def sections
      config.fetch("sections")
    end

    def filters
      config.fetch("filters")
    end

    def searches
      sections.flat_map { |section| section.fetch("searches") }
    end

    def automated(runs = SourceRun.latest_per_source.index_by(&:source))
      config.fetch("automated").map do |entry|
        keys = entry.fetch("sources")
        latest = runs.values_at(*keys).compact
        Automated.new(
          name: entry.fetch("name"),
          url: entry["url"],
          app_link: APP_LINKS.fetch(entry["app_link"], nil),
          note: entry["note"],
          sources: keys,
          interval: interval_for(keys.first),
          last_run_at: latest.map(&:created_at).max,
          failed: latest.any?(&:status_failed?),
          created_count: latest.sum(&:created_count),
          error_message: latest.filter_map { it.error_message.presence }.first
        )
      end
    end

    # LinkedIn alerts are imported every hour; the aggregator runs every 3 hours and each
    # source may ask for a longer interval (Sources::Base.min_interval).
    def interval_for(source_key)
      return 1.hour if source_key == "linkedin_alert"

      [ Sources.find(source_key)&.min_interval || 3.hours, 3.hours ].max
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

    def url_for(builder, query, filters = default_filters)
      q = ERB::Util.url_encode(query)

      case builder
      when "li_jobs", "li_jobs_world"
        region = builder == "li_jobs_world" ? "world_remote" : filters.fetch("li_region")
        "https://www.linkedin.com/jobs/search/?keywords=#{q}#{LINKEDIN_REGIONS.fetch(region)}&f_TPR=#{filters.fetch("li_period")}&sortBy=DD"
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
  end
end
