# Runs every aggregator source that is due (config/recurring.yml: every 3 hours), dedups,
# scores and saves the postings. One failing source never stops the others.
class FetchJobsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "fetch_jobs", on_conflict: :discard

  def perform(source_keys = nil, force: false)
    profile = Profile.current
    return unless profile.configured?

    started_at = Time.current
    sources = Sources.enabled(profile)
    sources = sources.select { Array(source_keys).include?(it.key) } if source_keys

    sources.each do |source_class|
      next unless force || source_class.due?

      run_source(source_class, profile)
    end

    NewPostingsNotifier.call(since: started_at)
  end

  private
    def run_source(source_class, profile)
      run = SourceRun.create!(source: source_class.key)
      source = source_class.new(profile)
      postings = source.fetch
      created = postings.count { JobIngestor.call(it).created? }
      run.finish!(fetched: postings.size, created:)
      run.update!(error_message: source.warnings.join("\n").truncate(1000)) if source.warnings.any?
    rescue StandardError => e
      run&.fail!(e)
      Rails.error.report(e, handled: true, context: { source: source_class.key })
    end
end
