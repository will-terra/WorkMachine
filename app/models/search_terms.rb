# The words of the profile, ready to go into the Radar searches and texts ({{stack_or}},
# {{cargos_en_or}}…). Lists come out as LinkedIn/X boolean groups: `(Rails OR "Ruby on Rails")`.
class SearchTerms
  PLACEHOLDER = /\{\{\s*([a-z_]+)\s*\}\}/
  MAX_ITEMS = 4
  SENIORITY_WORDS = {
    "junior" => [ "júnior", "junior", "jr" ],
    "mid" => [ "pleno", "mid-level", "mid level" ],
    "senior" => [ "sênior", "senior", "sr" ]
  }.freeze

  def initialize(profile)
    @profile = profile
    @area = profile.primary_area_record
  end

  # Fills the placeholders. Returns nil when one of them has nothing in the profile, so a search
  # that needs, say, a plan B is left out instead of shown half empty. In URLs the values are escaped.
  def render(text, url: false)
    missing = false
    rendered = text.to_s.gsub(PLACEHOLDER) do
      value = variables.fetch(::Regexp.last_match(1)) { raise KeyError, "Variável desconhecida no Radar: #{::Regexp.last_match(1)}" }
      missing = true if value.blank?
      url ? ERB::Util.url_encode(value) : value
    end
    rendered unless missing
  end

  # For prose (actions, notes): an empty placeholder becomes a neutral phrase.
  def render_text(text)
    text.to_s.gsub(PLACEHOLDER) { variables[::Regexp.last_match(1)].presence || "os termos do seu perfil" }
  end

  def variables
    @variables ||= {
      "stack" => phrase(main_skill),
      "stack_or" => any(essential_terms),
      "importantes_or" => any(names("important")),
      "extras_or" => any(names("extra")),
      "cargo" => titles_pt.first.to_s,
      "cargos_or" => any(titles_pt + titles_en, limit: 5),
      "cargos_en_or" => any(titles_en),
      "area" => phrase(@area&.name),
      "area_or" => any(@area&.terms),
      "quem_contrata_or" => any(@area&.hirers),
      "senioridade_or" => any(SENIORITY_WORDS[@profile.seniority]),
      "plano_b_or" => any(@profile.plan_b_terms),
      "dominios_or" => any(@profile.domains),
      "termos" => quoted_list(@profile.effective_search_terms)
    }
  end

  private
    def main_skill
      @profile.skills_at("essential").first&.fetch("name") || @profile.effective_search_terms.first || @profile.skill_names.first
    end

    def essential_terms
      terms = @profile.skills_at("essential").flat_map { [ it["name"], *it["synonyms"] ] }
      terms.presence || @profile.effective_search_terms
    end

    def names(level)
      @profile.skills_at(level).map { it["name"] }
    end

    def titles_pt
      @profile.target_titles.presence || @area&.titles_pt || []
    end

    def titles_en
      @profile.target_titles_en.presence || @area&.titles_en || []
    end

    # A term with spaces or hyphens goes in quotes.
    def phrase(term)
      term = term.to_s.squish
      term.match?(/[\s-]/) ? %("#{term}") : term
    end

    def any(terms, limit: MAX_ITEMS)
      items = Array(terms).map { phrase(it) }.compact_blank.uniq(&:downcase).first(limit)
      items.size > 1 ? "(#{items.join(" OR ")})" : items.first.to_s
    end

    # “rails”, “ruby” e “ruby on rails”
    def quoted_list(terms)
      items = Array(terms).first(MAX_ITEMS).map { "“#{it}”" }
      items.size > 1 ? "#{items[0..-2].join(", ")} e #{items.last}" : items.first.to_s
    end
end
