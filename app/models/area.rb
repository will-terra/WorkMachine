# A technology area from config/areas.yml (back-end, dados, UX/UI…): suggestions for the profile
# form and the AI, the words its searches use and the sources that make sense for it.
class Area
  KEYS = %w[name group titles_pt titles_en terms hirers title_filter skills wwr_feeds niche_sources].freeze

  attr_reader :key, *KEYS.map(&:to_sym)

  def self.all
    @all ||= YAML.load_file(Rails.root.join("config/areas.yml")).map { |key, attributes| new(key, attributes) }.freeze
  end

  def self.find(key)
    all.find { it.key == key.to_s }
  end

  def self.keys
    all.map(&:key)
  end

  # [["Desenvolvimento", [["Back-end", "backend"], …]], …] for grouped selects, in the interface
  # language (the names in config/areas.yml also go into the searches, so they stay Portuguese).
  def self.grouped_options
    all.group_by(&:group).map do |group, areas|
      [ I18n.t("areas.groups.#{group.parameterize(separator: "_")}", default: group), areas.map { [ it.display_name, it.key ] } ]
    end
  end

  def display_name
    I18n.t("areas.names.#{key}", default: name)
  end

  def initialize(key, attributes)
    @key = key
    KEYS.each { |name| instance_variable_set(:"@#{name}", attributes.fetch(name, name == "skills" ? {} : [])) }
    @name = attributes.fetch("name")
    @group = attributes.fetch("group")
  end

  # Suggested skills with the level each group starts at.
  def suggested_skills
    { "core" => "essential", "tools" => "important", "extras" => "extra" }.flat_map do |group, level|
      skills.fetch(group, []).map { { "name" => it, "level" => level } }
    end
  end
end
