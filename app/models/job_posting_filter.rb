# Filters and ordering of the triage screen (Vagas), built from the query string.
class JobPostingFilter
  KEYS = %w[triage source remote_scope seniority min_score period keyword salary q sort].freeze
  OPEN_TO_BRAZIL = "open".freeze
  OPEN_SCOPES = %w[brazil latam worldwide].freeze
  MIN_SCORES = [ 20, 35, 40, 50, 60, 75 ].freeze
  PERIODS = { "1" => [ 1.day, "Últimas 24 h" ], "3" => [ 3.days, "Últimos 3 dias" ],
              "7" => [ 7.days, "Últimos 7 dias" ], "30" => [ 30.days, "Últimos 30 dias" ] }.freeze
  SORTS = { "score" => "Mais bem classificadas", "recent" => "Mais novas" }.freeze
  DEFAULTS = { "triage" => "new", "sort" => "score" }.freeze

  def self.keywords
    JobScorer::KEYWORDS.map(&:first)
  end

  def initialize(params = {})
    @values = params.to_h.stringify_keys.slice(*KEYS).transform_values { it.to_s.strip }.compact_blank
    @values["triage"] = "new" unless JobPosting::TRIAGES.include?(@values["triage"]) || @values["triage"] == "all"
    @values["sort"] = "score" unless SORTS.key?(@values["sort"])
  end

  def [](key)
    @values[key.to_s]
  end

  # The values to keep in links (pagination, "Descartar todas").
  def to_params
    @values.dup
  end

  # True when anything other than the defaults is set.
  def active?
    @values.except(*DEFAULTS.keys).any? || @values["triage"] != "new"
  end

  def scope
    scope = JobPosting.all
    scope = scope.where(triage: self[:triage]) unless self[:triage] == "all"
    scope = scope.where(source: self[:source]) if JobPosting::SOURCES.include?(self[:source])
    scope = filter_region(scope)
    scope = scope.where(seniority: self[:seniority]) if JobPosting::SENIORITIES.include?(self[:seniority])
    scope = scope.where(score: self[:min_score].to_i..) if self[:min_score]
    scope = scope.where("COALESCE(posted_at, created_at) >= ?", PERIODS[self[:period]].first.ago) if PERIODS.key?(self[:period])
    scope = filter_keyword(scope)
    scope = scope.where.not(salary_text: [ nil, "" ]) if self[:salary] == "1"
    filter_text(scope)
  end

  def ordered
    self[:sort] == "recent" ? scope.recent.order(id: :desc) : scope.ranked
  end

  private
    def filter_region(scope)
      return scope.where(remote_scope: OPEN_SCOPES) if self[:remote_scope] == OPEN_TO_BRAZIL
      return scope unless JobPosting::REMOTE_SCOPES.include?(self[:remote_scope])

      scope.where(remote_scope: self[:remote_scope])
    end

    # matched_keywords is a JSON array of {"term", "points"} written by JobScorer.
    def filter_keyword(scope)
      return scope unless self.class.keywords.include?(self[:keyword])

      scope.where("EXISTS (SELECT 1 FROM json_each(job_postings.matched_keywords) WHERE json_extract(json_each.value, '$.term') = ?)", self[:keyword])
    end

    def filter_text(scope)
      return scope if self[:q].blank?

      term = "%#{JobPosting.sanitize_sql_like(self[:q])}%"
      scope.where("title LIKE :term OR company LIKE :term OR description LIKE :term", term:)
    end
end
