# Every 6 hours: the jobs saved, applied to or still in Novas whose company board the aggregator
# does not read (ClosedPostings).
class CheckClosedPostingsJob < ApplicationJob
  queue_as :default

  def perform
    ClosedPostings.check
  end
end
