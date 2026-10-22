# Numbers of the Métricas page: applications per week, the funnel (applied → answered →
# interview → offer), response and interview rates by origin, and which posting sources
# turn into saved jobs. An application counts as answered when its status shows a reply
# or responded_on is set, and as interviewed when its status or a company e-mail says so.
class FunnelMetrics
  PERIODS = { "30" => [ 30, "30 dias" ], "90" => [ 90, "90 dias" ], "all" => [ nil, "Tudo" ] }.freeze
  INTERVIEW_STATUSES = %w[ai_interview hr_interview tech_interview take_home offer].freeze
  INTERVIEW_EMAILS = %w[interview assessment offer].freeze
  MAX_WEEKS = 26

  Row = Data.define(:application, :answered, :interviewed, :offer)
  Stage = Data.define(:label, :count, :rate)
  Group = Data.define(:name, :total, :answered, :interviewed) do
    def response_rate = total.zero? ? 0 : (answered * 100.0 / total).round
    def interview_rate = total.zero? ? 0 : (interviewed * 100.0 / total).round
  end
  Source = Data.define(:source, :total, :saved) do
    def saved_rate = total.zero? ? 0 : (saved * 100.0 / total).round
  end

  attr_reader :period

  def initialize(period: "90", today: Date.current)
    @period = PERIODS.key?(period.to_s) ? period.to_s : "90"
    @today = today
  end

  def start_date
    days = PERIODS.fetch(@period).first
    days && @today - days
  end

  def rows
    @rows ||= begin
      scope = JobApplication.where.not(applied_on: nil).includes(:application_emails)
      scope = scope.where(applied_on: start_date..) if start_date
      scope.map do |application|
        emails = application.application_emails.map(&:category)
        Row.new(
          application:,
          answered: JobApplication::RESPONSE_STATUSES.include?(application.status) || application.responded_on.present? || emails.intersect?(ApplicationEmail::ANSWERS),
          interviewed: INTERVIEW_STATUSES.include?(application.status) || emails.intersect?(INTERVIEW_EMAILS),
          offer: application.status_offer? || emails.include?("offer")
        )
      end
    end
  end

  def applied = rows.size
  def answered = rows.count(&:answered)
  def interviewed = rows.count(&:interviewed)
  def offers = rows.count(&:offer)

  def response_rate = percent(answered, applied)
  def interview_rate = percent(interviewed, applied)

  def funnel
    [ [ "Aplicadas", applied ], [ "Responderam", answered ], [ "Entrevista ou teste", interviewed ], [ "Proposta", offers ] ]
      .map { |label, count| Stage.new(label:, count:, rate: percent(count, applied)) }
  end

  # Median days between applying and the first answer, for the applications that have both dates.
  def median_days_to_answer
    days = rows.filter_map { |row| (row.application.responded_on - row.application.applied_on).to_i if row.application.responded_on }.sort
    return if days.empty?

    days.size.odd? ? days[days.size / 2] : ((days[(days.size / 2) - 1] + days[days.size / 2]) / 2.0).round
  end

  # [[monday, count], ...] from the start of the period (or the first application) to this week.
  def weekly
    first = start_date || rows.map { it.application.applied_on }.min || @today
    weeks = [ ((@today.beginning_of_week - first.beginning_of_week).to_i / 7) + 1, MAX_WEEKS ].min
    counts = rows.group_by { it.application.applied_on.beginning_of_week }.transform_values(&:size)
    (0...weeks).map { |ago| @today.beginning_of_week - (weeks - 1 - ago).weeks }.map { [ it, counts.fetch(it, 0) ] }
  end

  def by_origin
    rows.group_by { it.application.origin.presence || "Sem origem" }
        .map { |name, list| Group.new(name:, total: list.size, answered: list.count(&:answered), interviewed: list.count(&:interviewed)) }
        .sort_by { [ -it.total, it.name ] }
  end

  def by_source
    scope = JobPosting.all
    scope = scope.where(created_at: start_date.beginning_of_day..) if start_date
    totals = scope.group(:source).count
    saved = scope.triage_saved.group(:source).count
    totals.map { |source, total| Source.new(source:, total:, saved: saved.fetch(source, 0)) }.sort_by { [ -it.saved_rate, -it.total ] }
  end

  private
    def percent(part, whole)
      whole.zero? ? 0 : (part * 100.0 / whole).round
    end
end
