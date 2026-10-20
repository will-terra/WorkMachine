# Looks for the public job board (Greenhouse, Lever, Ashby, Workable) of the companies you
# applied to and adds it to Empresas-alvo, so the aggregator keeps following those companies.
# Two ways: board links in the application's posting (TargetCompanyDiscovery), and asking each
# ATS API for slugs made from the company name. Each application is checked once.
class TargetCompanyFinder
  PROBES = {
    "greenhouse" => "https://boards-api.greenhouse.io/v1/boards/%s",
    "lever" => "https://api.lever.co/v0/postings/%s?mode=json&limit=1",
    "ashby" => "https://api.ashbyhq.com/posting-api/job-board/%s",
    "workable" => "https://apply.workable.com/api/v1/widget/accounts/%s"
  }.freeze
  # ATSs that return the company name, so a shorter slug can be confirmed by name.
  NAMED = %w[greenhouse workable].freeze
  GENERIC_WORDS = %w[inc llc ltd ltda sa s a gmbh corp corporation company co group grupo holding tecnologia
                     technologies technology tech software labs lab brasil brazil latam the].freeze
  PAUSE = 0.2

  def self.call(applications = JobApplication.where.not(status: "saved").where(board_checked_at: nil))
    new.call(applications)
  end

  # Returns the companies added.
  def call(applications)
    added = []
    applications.find_each do |application|
      added.concat(find_for(application))
      application.update_column(:board_checked_at, Time.current)
    end
    added
  end

  private
    def find_for(application)
      return [] if application.company.blank?

      boards = linked_boards(application) + probed_boards(application.company)
      boards.uniq { |ats, slug, _| [ ats, slug ] }.filter_map do |ats, slug, name|
        next if TargetCompany.exists?(ats:, board_slug: slug)

        TargetCompany.create!(name: name || application.company, ats:, board_slug: slug, active: true,
                              discovered_at: Time.current, discovered_from: application.job_posting)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
        nil
      end
    end

    def linked_boards(application)
      return [] unless application.job_posting

      TargetCompanyDiscovery.boards_in(application.job_posting).map { |ats, slug| [ ats, slug, application.company ] }
    end

    def probed_boards(company)
      return [] if TargetCompany.where("LOWER(name) = ?", company.downcase).exists?

      full, short = slugs_for(company)
      PROBES.keys.filter_map do |ats|
        candidates = NAMED.include?(ats) ? (full + short).uniq : full
        candidates.lazy.filter_map { |slug| probe(ats, slug, company) }.first
      end
    end

    # Full-name slugs ("sierrastudio", "sierra-studio") and, for ATSs that confirm the name,
    # slugs without generic words ("Grupo FCamara" → "fcamara").
    def slugs_for(company)
      words = I18n.transliterate(company.sub(/\(.*?\)/, "")).downcase.scan(/[a-z0-9]+/)
      meaningful = words - GENERIC_WORDS
      variants = ->(list) { list.empty? ? [] : [ list.join, list.join("-") ].uniq.select { it.length >= 3 } }
      [ variants.(words), variants.(meaningful) - variants.(words) ]
    end

    def probe(ats, slug, company)
      sleep PAUSE
      body = HttpClient.get_json(format(PROBES.fetch(ats), slug))
      return unless found?(ats, body)
      return [ ats, slug, nil ] unless NAMED.include?(ats)

      [ ats, slug, body["name"] ] if same_company?(body["name"], company)
    rescue HttpClient::Error, SocketError, SystemCallError, Timeout::Error
      nil
    end

    def found?(ats, body)
      case ats
      when "lever" then body.is_a?(Array)
      when "ashby" then body.is_a?(Hash) && body.key?("jobs")
      else body.is_a?(Hash) && body["name"].present?
      end
    end

    # Same words once generic ones are dropped, or one name starting with the other
    # ("Encora" and "Encora Digital"), never just a word in the middle ("Acme" and "Another Acme").
    def same_company?(board_name, company)
      a, b = [ board_name, company ].map { I18n.transliterate(it.to_s).downcase.scan(/[a-z0-9]+/) - GENERIC_WORDS }
      shorter, longer = [ a, b ].sort_by(&:size)
      shorter.any? && longer.first(shorter.size) == shorter
    end
end
