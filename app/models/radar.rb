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
