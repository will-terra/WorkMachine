# Finds public ATS boards (Greenhouse, Lever, Ashby, Workable) in the links of a new posting
# and registers the company in TargetCompany, so the aggregator starts reading its board.
# Companies found through a relevant posting (score >= Setting#notify_min_score) start active;
# the others wait as suggestions on the Empresas-alvo screen. This replaces the Google
# "site:" searches for these ATSs.
class TargetCompanyDiscovery
  BOARDS = {
    "greenhouse" => %r{(?:boards|job-boards)\.greenhouse\.io/(?:embed/job_(?:app|board)\?for=)?([a-z0-9][a-z0-9_-]*)}i,
    "lever" => %r{jobs\.lever\.co/([a-z0-9][a-z0-9._-]*)}i,
    "ashby" => %r{jobs\.ashbyhq\.com/([a-z0-9][a-z0-9._-]*)}i,
    "workable" => %r{apply\.workable\.com/([a-z0-9][a-z0-9-]*)}i
  }.freeze
  RESERVED = %w[embed api j jobs].freeze

  def self.call(posting)
    new(posting).call
  end

  # [[ats, slug], ...] of the boards linked from a posting.
  def self.boards_in(posting)
    new(posting).send(:boards)
  end

  def initialize(posting)
    @posting = posting
  end

  # Returns the companies created.
  def call
    boards.filter_map do |ats, slug|
      next if TargetCompany.exists?(ats:, board_slug: slug)

      TargetCompany.create!(
        name: company_name(ats, slug),
        ats:,
        board_slug: slug,
        active: relevant?,
        discovered_at: Time.current,
        discovered_from: @posting
      )
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      nil
    end
  end

  private
    def boards
      text = [ @posting.url, @posting.description, @posting.raw.to_json ].join(" ")
      BOARDS.flat_map { |ats, pattern| text.scan(pattern).flatten.map { [ ats, it.downcase ] } }
            .uniq.reject { |_, slug| RESERVED.include?(slug) }
    end

    # A company name only when the posting is from that same board; otherwise the slug.
    def company_name(ats, slug)
      own_board = @posting.url.to_s.match?(BOARDS.fetch(ats)) && @posting.url.to_s.downcase.include?(slug)
      (own_board && @posting.company.presence) || slug.tr("-_", "  ").titleize
    end

    def relevant?
      @posting.score >= Setting.current.notify_min_score
    end
end
