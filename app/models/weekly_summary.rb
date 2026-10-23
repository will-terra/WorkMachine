# The week in numbers (Monday to today) and one tip taken from them: the Sunday notification and
# the top of Métricas.
class WeeklySummary
  attr_reader :today

  def initialize(today: Date.current)
    @today = today
  end

  def week
    today.beginning_of_week..today
  end

  def applied
    @applied ||= JobApplication.where(applied_on: week).count
  end

  def applied_last_week
    @applied_last_week ||= JobApplication.where(applied_on: (week.begin - 7)..(week.begin - 1)).count
  end

  def answers
    @answers ||= emails_this_week.answers.count
  end

  def interviews
    @interviews ||= emails_this_week.where(category: "interview").count
  end

  def response_rate
    month.response_rate
  end

  # The aggregator's sources whose jobs you saved the most in the last 30 days.
  def best_sources
    month.by_source.select { it.total >= 5 && it.saved.positive? && JobPosting::MANUAL_SOURCES.exclude?(it.source) }.first(2).map { JobPosting.human_enum(:source, it.source) }
  end

  # One piece of advice, the first that fits: apply, follow up, lean on what works, change approach, triage.
  def tip
    @tip ||=
      if applied.zero?
        saved = JobPosting.triage_saved.where.missing(:job_application).count
        saved.positive? ? I18n.t("weekly_summary.tips.none_applied", count: saved) : I18n.t("weekly_summary.tips.none_applied_none_saved")
      elsif (due = JobApplication.follow_up_due(today).count).positive?
        I18n.t("weekly_summary.tips.follow_ups", count: due)
      elsif (origin = best_origin)
        I18n.t("weekly_summary.tips.best_origin", origin: origin.name, rate: origin.response_rate, average: quarter.response_rate)
      elsif month.applied >= 10 && response_rate < 10
        I18n.t("weekly_summary.tips.low_rate")
      elsif (waiting = JobPosting.triage_new.count) >= 20
        I18n.t("weekly_summary.tips.triage", count: waiting)
      else
        I18n.t("weekly_summary.tips.keep_going")
      end
  end

  def lines
    [
      [ I18n.t("weekly_summary.applied", count: applied), I18n.t("weekly_summary.last_week", count: applied_last_week),
        I18n.t("weekly_summary.answers", count: answers), I18n.t("weekly_summary.interviews", count: interviews) ].join(" · "),
      (I18n.t("weekly_summary.rate", rate: response_rate) if month.applied.positive?),
      (I18n.t("weekly_summary.sources", sources: best_sources.to_sentence) if best_sources.any?),
      I18n.t("weekly_summary.tip", tip:)
    ].compact
  end

  private
    def emails_this_week
      ApplicationEmail.where(received_at: week.begin.beginning_of_day..)
    end

    def month
      @month ||= FunnelMetrics.new(period: "30", today:)
    end

    def quarter
      @quarter ||= FunnelMetrics.new(period: "90", today:)
    end

    # An origin (LinkedIn, indicação…) that answers clearly more than your average.
    def best_origin
      average = quarter.response_rate
      quarter.by_origin.select { it.total >= 3 && it.response_rate >= average + 15 }.max_by(&:response_rate)
    end
end
