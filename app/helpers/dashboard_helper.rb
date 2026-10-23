module DashboardHelper
  # "follow-up hoje", "follow-up atrasado desde 21/10" or "aplicou em 12/10, sem resposta há 10 dias".
  def follow_up_when(application, today = Date.current)
    if (date = application.next_follow_up_on)
      date < today ? t("dashboard.follow_up.late", date: l(date, format: :day_month)) : t("dashboard.follow_up.today")
    else
      days = (today - application.applied_on).to_i
      t("dashboard.follow_up.waiting", date: l(application.applied_on, format: :day_month), count: days)
    end
  end

  # "busca 12:30 → 15:00": the last aggregator run (scheduled or "Buscar agora") and the next
  # scheduled one.
  def fetch_line(last_at, next_at = FetchJobsJob.next_run_at)
    last_at ? t("dashboard.fetch.next", last: clock(last_at), next: clock(next_at)) : t("dashboard.fetch.none")
  end

  # "12:40" today, "ontem 12:40" or "20/10 12:40" otherwise.
  def clock(time)
    time.to_date == Date.current ? l(time, format: :hour) : short_time(time)
  end
end
