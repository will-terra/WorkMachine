module JobPostingsHelper
  # "Lumen Labs · via Greenhouse · Mundo todo · Sênior · há 3 h"
  def posting_meta(posting)
    [ posting.display_company, "via #{posting.human_enum(:source)}", posting.human_enum(:remote_scope),
      (posting.human_enum(:seniority) unless posting.seniority_unknown?), posted_ago(posting.posted_or_found_at) ].compact.join(" · ")
  end

  # "há 3 h", "ontem" or "há 4 dias".
  def posted_ago(time)
    hours = ((Time.current - time) / 1.hour).floor
    if hours < 1 then "agora há pouco"
    elsif hours < 24 then "há #{hours} h"
    elsif hours < 48 then "ontem"
    else "há #{hours / 24} dias"
    end
  end

  # The terms that made the score, as tags: negative ones in amber. With a limit, the heaviest first.
  def posting_terms(posting, limit: nil)
    matches = posting.matched_keywords
    matches = matches.sort_by { -it["points"].abs }.first(limit) if limit
    safe_join(matches.map { |match| tag.span("#{match["term"]} #{points(match["points"])}", class: [ "chip", ("chip-warn" if match["points"].negative?) ]) })
  end
end
