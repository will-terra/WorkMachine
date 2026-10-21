# The person who uses this installation: who they are, what they look for and how postings are
# scored and searched for them. One row (Profile.current); everything that used to be written for
# one person in the code (scorer weights, source terms, Radar searches, the AI profile) reads it.
class Profile < ApplicationRecord
  LEVELS = { "essential" => 30, "important" => 10, "extra" => 5 }.freeze
  AVOID_POINTS = -15
  SENIORITIES = %w[junior mid senior].freeze
  REGIONS = %w[brazil latam worldwide us europe].freeze
  WORK_MODES = %w[remote hybrid onsite].freeze
  LIST_ATTRIBUTES = %i[target_titles target_titles_en work_modes regions avoid_terms search_terms plan_b_terms domains].freeze
  # Changing these changes the score of every posting.
  SCORING_ATTRIBUTES = %w[skills avoid_terms regions seniority years_experience target_titles target_titles_en].freeze
  MAX_SKILLS = 60
  MAX_DREAM_POSTINGS = 5

  validates :seniority, inclusion: { in: SENIORITIES }
  validates :years_experience, numericality: { only_integer: true, in: 0..60 }, allow_nil: true
  validates :primary_area, inclusion: { in: -> { Area.keys } }, allow_blank: true
  validates :plan_b_area, inclusion: { in: -> { Area.keys } }, allow_blank: true
  validate :lists_are_known, :skills_are_valid, :time_zone_exists
  validates :dream_posting_ids, length: { maximum: MAX_DREAM_POSTINGS }

  after_update_commit :rescore_postings, if: -> { saved_changes.keys.intersect?(SCORING_ATTRIBUTES) }

  LIST_ATTRIBUTES.each do |attribute|
    define_method(:"#{attribute}=") do |value|
      clear_rules
      super(self.class.clean_list(value))
    end
  end

  # The profile of this installation, loaded once per request or job. Unsaved (and empty)
  # until the person fills it in.
  def self.current
    Current.profile ||= first || new
  end

  # Lists come from the form as text (one per line or separated by commas) or as arrays.
  def self.clean_list(value)
    items = value.is_a?(String) ? value.split(/[\n,;]/) : Array(value)
    items.map { it.to_s.squish }.compact_blank.uniq { it.downcase }
  end

  # Accents and case do not matter when matching terms: "Gestão Pública" matches "gestao publica".
  def self.normalize_text(*texts)
    I18n.transliterate(texts.flatten.compact.join("\n"), replacement: " ").downcase
  end

  # One regex for a list of terms, with word edges that also work around "C#", ".NET" or "Node.js".
  def self.terms_regex(terms)
    patterns = Array(terms).map { normalize_text(it).squish }.compact_blank.uniq.sort_by { -it.length }
    return if patterns.empty?

    alternatives = patterns.map { Regexp.escape(it).gsub("\\ ", "\\s+") }
    Regexp.new("(?<![a-z0-9])(?:#{alternatives.join("|")})(?![a-z0-9])")
  end

  def skills=(value)
    clear_rules
    items = value.is_a?(Hash) ? value.values : Array(value)
    super(items.filter_map { self.class.clean_skill(it) }.uniq { it["name"].downcase })
  end

  def self.clean_skill(skill)
    skill = skill.to_h.stringify_keys
    name = skill["name"].to_s.squish
    return if name.blank? || skill["_destroy"].to_s == "1"

    level = LEVELS.key?(skill["level"].to_s) ? skill["level"].to_s : "important"
    { "name" => name, "level" => level, "synonyms" => clean_list(skill["synonyms"]).reject { it.casecmp?(name) } }
  end

  def configured?
    skills.any? || search_terms.any?
  end

  def areas
    [ primary_area, plan_b_area ].compact_blank.uniq.filter_map { Area.find(it) }
  end

  def primary_area_record
    Area.find(primary_area)
  end

  def skill_names
    skills.map { it["name"] }
  end

  def skills_at(level)
    skills.select { it["level"] == level }
  end

  # [{"term", "points"}] for each skill found in the normalized text, in the profile's order.
  def skill_matches(normalized_text)
    skill_rules.filter_map do |name, points, regex|
      { "term" => name, "points" => points } if regex.match?(normalized_text)
    end
  end

  def avoid_matches(normalized_text)
    avoid_rules.filter_map { |term, regex| { "term" => "evitar: #{term}", "points" => AVOID_POINTS } if regex.match?(normalized_text) }
  end

  # What the aggregator searches for and keeps: the search terms, or the essential skills.
  def effective_search_terms
    search_terms.presence || skills_at("essential").flat_map { [ it["name"], *it["synonyms"] ] }
  end

  def relevant?(*texts)
    search_regex&.match?(self.class.normalize_text(texts)) || false
  end

  # Plan B postings must show at least two of its terms (React with TypeScript or Next.js).
  def plan_b_relevant?(*texts)
    return false if plan_b_terms.empty?

    text = self.class.normalize_text(texts)
    found = plan_b_terms.count { self.class.terms_regex([ it ]).match?(text) }
    found >= [ 2, plan_b_terms.size ].min
  end

  def target_title?(title)
    target_title_regex&.match?(self.class.normalize_text(title)) || false
  end

  # Words that make a title worth keeping from a company board (Greenhouse, Lever…).
  def board_title_regex
    @board_title_regex ||= self.class.terms_regex(areas.flat_map(&:title_filter).presence || Area.find("fullstack").title_filter)
  end

  def accepts_region?(region)
    regions.include?(region)
  end

  def reload(*)
    clear_rules
    super
  end

  private
    def skill_rules
      @skill_rules ||= skills.map { [ it["name"], LEVELS.fetch(it["level"]), self.class.terms_regex([ it["name"], *it["synonyms"] ]) ] }
    end

    def avoid_rules
      @avoid_rules ||= avoid_terms.map { [ it, self.class.terms_regex([ it ]) ] }
    end

    def search_regex
      @search_regex ||= self.class.terms_regex(effective_search_terms)
    end

    def target_title_regex
      @target_title_regex ||= self.class.terms_regex(target_titles + target_titles_en)
    end

    def clear_rules
      @skill_rules = @avoid_rules = @search_regex = @target_title_regex = @board_title_regex = nil
    end

    def rescore_postings
      RescorePostingsJob.perform_later
    end

    def lists_are_known
      errors.add(:regions, :inclusion) unless (regions - REGIONS).empty?
      errors.add(:work_modes, :inclusion) unless (work_modes - WORK_MODES).empty?
    end

    def skills_are_valid
      errors.add(:skills, :too_long, count: MAX_SKILLS) if skills.size > MAX_SKILLS
    end

    def time_zone_exists
      errors.add(:time_zone, :inclusion) unless ActiveSupport::TimeZone[time_zone.to_s]
    end
end
