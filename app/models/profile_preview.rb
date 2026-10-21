# What saving the profile form would change, without saving: the scores of the latest postings
# before and after, the Radar searches and what the aggregator will search for.
class ProfilePreview
  SAMPLE_SIZE = 20

  Score = Data.define(:posting, :before, :after) do
    def change = after - before
  end

  attr_reader :profile

  def initialize(current, attributes)
    @current = current
    @profile = Profile.new(current.attributes.except("id", "created_at", "updated_at"))
    @profile.assign_attributes(attributes)
    @profile.drop_default_overrides
  end

  def scores
    @scores ||= JobPosting.recent.limit(SAMPLE_SIZE).map do |posting|
      result = JobScorer.call(title: posting.title, description: posting.description, location_text: posting.location_text,
                              remote_scope_hint: posting.remote_scope_hint, profile:)
      Score.new(posting:, before: posting.score, after: result.score)
    end
  end

  def changed_scores
    scores.count { it.change.nonzero? }
  end

  # The searches whose query changes with the new profile.
  def changed_searches
    before = Radar.searches_for(@current).to_h { [ it["key"], it["query"] ] }
    Radar.searches_for(profile).reject { before[it["key"]] == it["query"] }
  end

  def searches
    Radar.searches_for(profile)
  end

  def sources
    Sources.enabled(profile).map { JobPosting.human_enum(:source, it.key) }
  end
end
