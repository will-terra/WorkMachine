# Scores a posting from 0 to 100 against Ana's stack (docs/PLANO.md, section 3) and
# detects region and seniority. Every rule that fired goes to matched_keywords, so the
# triage screen can explain the score.
class JobScorer
  KEYWORDS = [
    [ "rails", /\bruby on rails\b|\brails\b/i, 30 ],
    [ "ruby", /\bruby\b/i, 10 ],
    [ "react", /\breact(?:\.?js)?\b/i, 10 ],
    [ "hotwire/turbo/stimulus", /\b(?:hotwire|turbo|stimulus)\b/i, 8 ],
    [ "sidekiq", /\bsidekiq\b/i, 5 ],
    [ "postgres", /\bpostgres(?:ql)?\b/i, 5 ],
    [ "typescript", /\btypescript\b/i, 4 ],
    [ "docker/kubernetes", /\b(?:docker|kubernetes|k8s)\b/i, 3 ],
    [ "govtech", /\bgovtech\b|\bpublic sector\b|\bsetor p[úu]blico\b|\bgest[ãa]o p[úu]blica\b/i, 5 ]
  ].freeze

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

  EXPERIENCE_PENALTY = -15
  LONG_EXPERIENCE = /\b(?:[7-9]|1\d)\s*\+?\s*(?:years|yrs|anos)\b/i
  SOME_EXPERIENCE_PENALTY = -10
  SOME_EXPERIENCE = /\b[56]\s*\+?\s*(?:years|yrs|anos)\b/i
  SENIOR_PENALTY = -10
  STAFF_PENALTY = -10
  STAFF = /\b(?:staff|principal)\b/i
  RESTRICTED_TERM = "local restrito".freeze
  MANAGEMENT_PENALTY = -15
  MANAGEMENT = /\b(?:manager|head of|director|diretor|vp|vice president|cto|gerente)\b/i

  SENIOR = /\b(?:senior|sênior|sr\.?|staff|principal|lead|líder)\b/i
  JUNIOR = /\b(?:junior|júnior|jr\.?|intern|internship|estágio|estagiári[oa]|trainee)\b/i
  MID = /\b(?:mid[- ]?level|mid|pleno|intermediate)\b|\b(?:engineer|developer) ii\b/i

  Result = Data.define(:score, :matched_keywords, :remote_scope, :seniority)

  def self.call(...)
    new(...).call
  end

  def initialize(title:, description: nil, location_text: nil, remote_scope_hint: nil)
    @title = title.to_s
    @location = location_text.to_s
    @text = [ @title, @location, description ].compact.join("\n")
    @hint = remote_scope_hint
  end

  def call
    matches = KEYWORDS.filter_map { |term, pattern, points| { "term" => term, "points" => points } if @text.match?(pattern) }
    remote_scope = detect_remote_scope

    matches << { "term" => "região aberta", "points" => REGION_BONUS } if @text.match?(REGION)
    matches << { "term" => "só EUA/Canadá", "points" => REGION_PENALTY } if remote_scope == "us_only"
    matches << { "term" => "só Europa", "points" => REGION_PENALTY } if remote_scope == "europe_only"
    matches << { "term" => RESTRICTED_TERM, "points" => REGION_PENALTY } if remote_scope == "unknown" && restricted_location?
    if @text.match?(LONG_EXPERIENCE)
      matches << { "term" => "7+ anos", "points" => EXPERIENCE_PENALTY }
    elsif @text.match?(SOME_EXPERIENCE)
      matches << { "term" => "5+ anos", "points" => SOME_EXPERIENCE_PENALTY }
    end
    if @title.match?(STAFF)
      matches << { "term" => "staff/principal", "points" => STAFF_PENALTY }
    elsif @title.match?(SENIOR)
      matches << { "term" => "sênior", "points" => SENIOR_PENALTY }
    end
    matches << { "term" => "gestão", "points" => MANAGEMENT_PENALTY } if @title.match?(MANAGEMENT)

    Result.new(
      score: matches.sum { it["points"] }.clamp(0, 100),
      matched_keywords: matches,
      remote_scope:,
      seniority: detect_seniority
    )
  end

  private
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
