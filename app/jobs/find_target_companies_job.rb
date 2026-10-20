# Looks for the job boards of the companies you applied to (TargetCompanyFinder) and, when
# it adds any, fetches their boards right away.
class FindTargetCompaniesJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "find_target_companies", on_conflict: :discard

  def perform
    added = TargetCompanyFinder.call
    FetchJobsJob.perform_later(added.map(&:ats).uniq, force: true) if added.any?
  end
end
