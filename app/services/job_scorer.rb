# Scores a posting from 0 to 100 against the profile (Profile.current) and detects region and
# seniority. Skill points come from the profile's levels; region, experience and seniority rules
# are relative to what the profile accepts. Every rule that fired goes to matched_keywords, so the
# triage screen can explain the score.
class JobScorer
  REGION_BONUS = 15
  REGION = /\b(?:latam|latin america|south america|brazil|brasil|anywhere|worldwide)\b/i
  OPEN_REGION = /\b(?:latam|latin|south america|brazil|brasil|anywhere|worldwide|global|international)\b/i

  REGION_PENALTY = -40
  US_ONLY = /\b(?:US|USA|U\.S\.)(?:\s*(?:\/|&|and|or)\s*Canada)?[- ]only\b|must be (?:located|based|residing) in the (?:US|U\.S\.|United States)|\bUS citizens?(?:hip)?\b|\bsecurity clearance\b/i
  US_STATE = /,\s*(?:AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY|DC)\b/
  US_CITY = /\b(?:New York|San Francisco|Seattle|Boston|Chicago|Austin|Los Angeles|Denver|Atlanta|Toronto|Vancouver|Montreal)\b/i
  NORTH_AMERICA = Regexp.union(/\b(?:US|USA|U\.S\.A?\.?|United States|Canada|North America|Estados Unidos|EUA|Canadá|América do Norte)\b/i, US_STATE, US_CITY)
  EUROPE_ONLY = /\b(?:EU|Europe|UK)[- ]only\b|must be (?:located|based|residing) in (?:the )?(?:EU|Europe|UK)\b/i
  EUROPE = /\b(?:Europe|EMEA|EU|UK|United Kingdom|Germany|France|Spain|Portugal|Poland|Netherlands|Ireland|Italy|Sweden|CET|Europa|Reino Unido|Alemanha|França|Espanha|Polônia|Holanda|Países Baixos|Irlanda|Itália|Suécia)\b/i
  OTHER_COUNTRY = /\b(?:India|Índia|Pakistan|Paquistão|Bangladesh|Philippines|Filipinas|Australia|Austrália|New Zealand|Nova Zelândia|Japan|Japão|Singapore|Singapura|Israel|South Africa|África do Sul|Nigeria|Nigéria|Kenya|Quênia|Egypt|Egito|Turkey|Turquia|UAE|Dubai|China|Korea|Coreia|Vietnam|Vietnã|Indonesia|Indonésia|Malaysia|Malásia|Thailand|Tailândia|APAC)\b/i
  BRAZIL = /\b(?:brazil|brasil|são paulo|sao paulo|rio de janeiro|porto alegre|curitiba|belo horizonte|florian[óo]polis)\b/i
  LATAM = /\b(?:latam|latin america|south america|américa latina|america latina)\b/i
  WORLDWIDE = /\b(?:anywhere|worldwide|global)\b/i
  OPEN_REGIONS = %w[brazil latam worldwide].freeze
  RESTRICTED_TERM = "local restrito".freeze

  # "5+ years", "8 anos"… The largest number asked for counts; above 19 it is not about experience.
  EXPERIENCE = /\b(\d{1,2})\s*\+?\s*(?:years|yrs|anos)\b/i
  EXPERIENCE_RANGE = 1..19
  # Asking for this many years more than the profile has costs these points.
  EXPERIENCE_GAPS = { 4 => -15, 2 => -10 }.freeze
  ABOVE_LEVEL_PENALTY = -10
  MANAGEMENT_PENALTY = -15
  MANAGEMENT = /\b(?:manager|head of|director|diretor|vp|vice president|cto|gerente)\b/i

  STAFF = /\b(?:staff|principal)\b/i
  SENIOR = /\b(?:senior|sênior|sr\.?|staff|principal|lead|líder)\b/i
  JUNIOR = /\b(?:junior|júnior|jr\.?|intern|internship|estágio|estagiári[oa]|trainee)\b/i
  MID = /\b(?:mid[- ]?level|mid|pleno|intermediate)\b|\b(?:engineer|developer) ii\b/i
  LEVELS = %w[junior mid senior staff].freeze
  LEVEL_TERMS = { "mid" => "pleno", "senior" => "sênior", "staff" => "staff/principal" }.freeze

  Result = Data.define(:score, :matched_keywords, :remote_scope, :seniority)

  # The terms the scorer and AutoDismissal store are Portuguese keys; on screen they follow the
  # interface language. Skills and terms of the profile are shown as they are.
  TERM_KEYS = { "região aberta" => "open_region", "só EUA/Canadá" => "us_only", "só Europa" => "europe_only", RESTRICTED_TERM => "restricted",
                "gestão" => "management", "pleno" => "mid", "sênior" => "senior", "staff/principal" => "staff" }.freeze

  def self.human_term(term)
    if (key = TERM_KEYS[term]) then I18n.t("job_scorer.terms.#{key}")
    elsif (years = term.to_s[/\A(\d+)\+ anos\z/, 1]) then I18n.t("job_scorer.terms.years", count: years.to_i)
    elsif (min = term.to_s[/\Anota abaixo de (\d+)\z/, 1]) then I18n.t("job_scorer.terms.below", min:)
    else term
    end
  end

  def self.call(...)
    new(...).call
  end

  def initialize(title:, description: nil, location_text: nil, remote_scope_hint: nil, profile: Profile.current)
    @title = title.to_s
    @location = location_text.to_s
    @text = [ @title, @location, description ].compact.join("\n")
    @hint = remote_scope_hint
    @profile = profile
  end

  def call
    normalized = Profile.normalize_text(@text)
    remote_scope = detect_remote_scope
    matches = @profile.skill_matches(normalized)

    matches.concat(region_rules(remote_scope))
    matches << experience_rule if experience_rule
    matches << level_rule if level_rule
    matches << { "term" => "gestão", "points" => MANAGEMENT_PENALTY } if management?
    matches.concat(@profile.avoid_matches(normalized))

    Result.new(
      score: matches.sum { it["points"] }.clamp(0, 100),
      matched_keywords: matches,
      remote_scope:,
      seniority: detect_seniority
    )
  end

  private
    def region_rules(remote_scope)
      rules = []
      rules << { "term" => "região aberta", "points" => REGION_BONUS } if @text.match?(REGION) && @profile.regions.intersect?(OPEN_REGIONS)
      rules << { "term" => "só EUA/Canadá", "points" => REGION_PENALTY } if remote_scope == "us_only" && !@profile.accepts_region?("us")
      rules << { "term" => "só Europa", "points" => REGION_PENALTY } if remote_scope == "europe_only" && !@profile.accepts_region?("europe")
      rules << { "term" => RESTRICTED_TERM, "points" => REGION_PENALTY } if remote_scope == "unknown" && restricted_location?
      rules
    end

    def experience_rule
      return @experience_rule if defined?(@experience_rule)

      @experience_rule =
        if (years = @profile.years_experience) && (asked = experience_asked)
          gap, points = EXPERIENCE_GAPS.find { |gap, _| asked - years >= gap }
          { "term" => "#{asked}+ anos", "points" => points } if gap
        end
    end

    def experience_asked
      @text.scan(EXPERIENCE).flatten.map(&:to_i).select { EXPERIENCE_RANGE.cover?(it) }.max
    end

    # A title above the profile's level (sênior for a mid-level profile) costs a few points.
    def level_rule
      return @level_rule if defined?(@level_rule)

      level = title_level
      @level_rule =
        if level && LEVELS.index(level) > LEVELS.index(@profile.seniority)
          { "term" => LEVEL_TERMS.fetch(level), "points" => ABOVE_LEVEL_PENALTY }
        end
    end

    def title_level
      return "staff" if @title.match?(STAFF)
      return "senior" if @title.match?(SENIOR)

      "mid" if @title.match?(MID)
    end

    # Management titles cost points, unless they are what the profile looks for (Product Manager).
    def management?
      @title.match?(MANAGEMENT) && !@profile.target_title?(@title)
    end

    def detect_remote_scope
      return "us_only" if @text.match?(US_ONLY) || location_segments_all?(NORTH_AMERICA)
      return "europe_only" if @text.match?(EUROPE_ONLY) || location_segments_all?(EUROPE)
      return @hint if @hint.present?

      [ @location, @text ].each do |text|
        return "brazil" if text.match?(BRAZIL)
        return "latam" if text.match?(LATAM)
        return "worldwide" if text.match?(WORLDWIDE)
      end
      "unknown"
    end

    # "Remote, Canada; Remote, Poland" lists the countries where the company hires.
    def location_segments
      @location_segments ||=
        @location.match?(OPEN_REGION) || @location.match?(BRAZIL) ? [] : @location.split(/[;|]/).map(&:strip).compact_blank
    end

    def location_segments_all?(region)
      location_segments.any? && location_segments.all? { it.match?(region) }
    end

    # Only named countries outside Brazil/LATAM (e.g. "Remote, Canada; Remote, India").
    def restricted_location?
      location_segments.any? && location_segments.all? { it.match?(Regexp.union(NORTH_AMERICA, EUROPE, OTHER_COUNTRY)) }
    end

    def detect_seniority
      return "senior" if @title.match?(SENIOR)
      return "junior" if @title.match?(JUNIOR)
      return "mid" if @title.match?(MID) || @text.match?(/\b(?:mid[- ]level|pleno)\b/i)

      "unknown"
    end
end
