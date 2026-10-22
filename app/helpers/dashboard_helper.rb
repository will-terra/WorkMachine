module DashboardHelper
  # "follow-up hoje", "follow-up atrasado desde 21/10" or "aplicou em 12/10, sem resposta há 10 dias".
  def follow_up_when(application, today = Date.current)
    if (date = application.next_follow_up_on)
      date < today ? "follow-up atrasado desde #{l(date, format: "%d/%m")}" : "follow-up hoje"
    else
      days = (today - application.applied_on).to_i
      "aplicou em #{l(application.applied_on, format: "%d/%m")}, sem resposta há #{pluralize(days, "dia", plural: "dias")}"
    end
  end

  # "busca 12:00 → 15:00": the last aggregator run and the next one (it runs every 3 hours).
  def fetch_line(last_at)
    return "nenhuma busca ainda" unless last_at

    next_at = last_at + 3.hours
    next_at.future? ? "busca #{clock(last_at)} → #{clock(next_at)}" : "busca #{clock(last_at)}"
  end

  # "12:40" today, "ontem 12:40" or "20/10 12:40" otherwise.
  def clock(time)
    time.to_date == Date.current ? l(time, format: "%H:%M") : short_time(time)
  end
end
