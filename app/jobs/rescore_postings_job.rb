# Recalculates the score of every posting after the profile changes (skills, levels, regions…).
class RescorePostingsJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: "rescore_postings"

  def perform
    profile = Profile.current
    JobPosting.find_each { it.rescore!(profile) }
  end
end
