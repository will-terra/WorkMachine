# Which technologies of a job a CV mentions ("7 of 10 terms of the job are in your CV"). The terms
# are the profile's skills (with their synonyms) and the skills of every area that the job names.
class KeywordCoverage
  Result = Data.define(:covered, :missing) do
    def total = covered.size + missing.size
  end

  def self.call(posting, text, profile = Profile.current)
    new(profile).call(posting, text)
  end

  def initialize(profile = Profile.current)
    @profile = profile
  end

  def call(posting, text)
    job = Profile.normalize_text(posting.title, posting.description)
    cv = Profile.normalize_text(text)
    terms = groups.select { |_name, regex| regex.match?(job) }
    covered, missing = terms.partition { |_name, regex| regex.match?(cv) }
    Result.new(covered: covered.map(&:first), missing: missing.map(&:first))
  end

  private
    # [name, regex], one per technology: the profile's skills (their synonyms count), then the
    # areas' skills that do not repeat one of them ("Ruby on Rails" when the profile has "Rails").
    def groups
      @groups ||= begin
        own = @profile.skills.filter_map { |skill| [ skill["name"], Profile.terms_regex([ skill["name"], *skill["synonyms"] ]) ] if skill["name"].present? }
        areas = Area.all.flat_map { it.skills.values.flatten }.uniq.filter_map do |name|
          normalized = Profile.normalize_text(name)
          [ name, Profile.terms_regex([ name ]) ] unless own.any? { |_, regex| regex.match?(normalized) }
        end
        (own + areas).uniq { |name, _| Profile.normalize_text(name).squish }
      end
    end
end
