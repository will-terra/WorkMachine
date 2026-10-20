# Searches and places from config/radar.yml (ported from docs/radar-vagas-rails.html).
class Radar
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
  end
end
