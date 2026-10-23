# Jobs that leave their company's public board (Greenhouse, Lever, Ashby, Workable) are closed:
# they get closed_at, and the ones still waiting in Novas leave the triage (auto-dismissed, unless
# you saved them by hand). A job that comes back to the board reopens. One request per board.
#
# The aggregator marks the boards it reads (Sources::AtsBoard); CheckClosedPostingsJob checks the
# other ones: jobs saved by the extension or from alerts whose link is an ATS job page.
module ClosedPostings
  REASON = "vaga encerrada".freeze
  WINDOW = 120.days # older jobs are not checked
  LIST_URLS = {
    "greenhouse" => "https://boards-api.greenhouse.io/v1/boards/%s/jobs",
    "lever" => "https://api.lever.co/v0/postings/%s?mode=json",
    "ashby" => "https://api.ashbyhq.com/posting-api/job-board/%s",
    "workable" => "https://apply.workable.com/api/v1/widget/accounts/%s"
  }.freeze
  # The job pages of each ATS: [ats, board, job id] from a link.
  JOB_URLS = {
    "greenhouse" => %r{greenhouse\.io/([^/?#]+)/jobs/(\d+)}i,
    "lever" => %r{jobs\.lever\.co/([^/?#]+)/([0-9a-f-]{36})}i,
    "ashby" => %r{jobs\.ashbyhq\.com/([^/?#]+)/([0-9a-f-]{36})}i,
    "workable" => %r{apply\.workable\.com/([^/?#]+)/j/([0-9a-z]+)}i
  }.freeze

  module_function

  # [ats, board, id] of a job, from the source that read it or from its link.
  def ref(posting)
    if LIST_URLS.key?(posting.source) && posting.raw["board"].present? && posting.external_id.present?
      [ posting.source, posting.raw["board"], posting.external_id.to_s ]
    else
      JOB_URLS.each { |ats, regex| (match = posting.url.to_s.match(regex)) and return [ ats, match[1].downcase, match[2] ] }
      nil
    end
  end

  # The board's open jobs are ids; every tracked job of that board not among them is closed.
  def mark(ats, board, ids, now: Time.current)
    open_ids = ids.map(&:to_s).to_set
    tracked.each do |posting, (posting_ats, posting_board, id)|
      next unless posting_ats == ats && posting_board.casecmp?(board)

      open_ids.include?(id) ? reopen(posting) : close(posting, now)
    end
  end

  # Every board with tracked jobs that the aggregator did not just read.
  def check(since: 6.hours.ago)
    read = TargetCompany.active.where(last_fetched_at: since..).pluck(:ats, :board_slug).map { |ats, board| [ ats, board.downcase ] }
    boards = tracked.map { |_posting, (ats, board, _id)| [ ats, board.downcase ] }.uniq - read
    boards.each do |ats, board|
      mark(ats, board, open_ids(ats, board))
    rescue HttpClient::Error => e
      mark(ats, board, []) if e.status == 404 # the whole board is gone
    end
  end

  def open_ids(ats, board)
    data = HttpClient.get_json(format(LIST_URLS.fetch(ats), board))
    case ats
    when "greenhouse" then data.fetch("jobs", []).map { it["id"] }
    when "lever" then data.map { it["id"] }
    when "ashby" then data.fetch("jobs", []).reject { it["isListed"] == false }.map { it["id"] }
    when "workable" then data.fetch("jobs", []).map { it["shortcode"] }
    end
  end

  # Recent jobs worth watching (in Novas, saved, applied to, or closed by us), with their ATS ref.
  def tracked
    applied = JobApplication.where.not(job_posting_id: nil).select(:job_posting_id)
    scope = JobPosting.where(created_at: WINDOW.ago..)
    scope = scope.where(triage: %w[new saved]).or(scope.where(id: applied)).or(scope.where(auto_dismissed_reason: REASON))
    scope.filter_map { |posting| (ref = ref(posting)) && [ posting, ref ] }
  end

  def close(posting, now)
    return if posting.closed_at

    attributes = { closed_at: now }
    attributes.merge!(triage: "dismissed", auto_dismissed_reason: REASON) if posting.triage_new? && JobPosting::MANUAL_SOURCES.exclude?(posting.source)
    posting.update!(attributes)
  end

  def reopen(posting)
    return unless posting.closed_at

    attributes = { closed_at: nil }
    attributes.merge!(triage: "new", auto_dismissed_reason: nil) if posting.auto_dismissed_reason == REASON
    posting.update!(attributes)
  end
end
