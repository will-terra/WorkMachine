# Saves one posting coming from any source (aggregator, LinkedIn alert, extension, manual):
# dedups by normalized URL and company + title, scores new postings, and fills blank
# fields of an existing posting with the new data (rescoring if description or location arrived).
class JobIngestor
  FILLABLE = %i[company description location_text salary_text posted_at].freeze

  Result = Data.define(:posting, :status) do
    def created? = status == :created
    def duplicate? = status == :duplicate
    def invalid? = status == :invalid
  end

  def self.call(attributes)
    new(attributes).call
  end

  def initialize(attributes)
    @attributes = attributes.to_h.symbolize_keys
    @hint = @attributes.delete(:remote_scope_hint)
    # Kept in raw so that rescoring later gives the same region.
    @attributes[:raw] = (@attributes[:raw] || {}).merge("remote_scope_hint" => @hint) if @hint
  end

  def call
    existing = JobPosting.find_duplicate(url: @attributes[:url], company: @attributes[:company], title: @attributes[:title])
    return enrich(existing) if existing

    posting = JobPosting.new(@attributes)
    apply_score(posting)
    AutoDismissal.apply(posting)
    if posting.save
      TargetCompanyDiscovery.call(posting)
      return Result.new(posting:, status: :created)
    end

    taken = posting.errors.of_kind?(:url, :taken)
    taken ? Result.new(posting: JobPosting.find_by(url: posting.url), status: :duplicate) : Result.new(posting:, status: :invalid)
  rescue ActiveRecord::RecordNotUnique
    Result.new(posting: JobPosting.find_by(url: UrlNormalizer.call(@attributes[:url])), status: :duplicate)
  end

  private
    def enrich(posting)
      FILLABLE.each do |field|
        posting[field] = @attributes[field] if posting[field].blank? && @attributes[field].present?
      end
      apply_score(posting) if posting.description_changed? || posting.location_text_changed?
      posting.save! if posting.changed?
      Result.new(posting:, status: :duplicate)
    end

    def apply_score(posting)
      result = JobScorer.call(title: posting.title, description: posting.description,
                              location_text: posting.location_text, remote_scope_hint: @hint || posting.remote_scope_hint)
      posting.assign_attributes(score: result.score, matched_keywords: result.matched_keywords,
                                remote_scope: result.remote_scope, seniority: result.seniority)
    end
end
