# Dismisses on arrival the postings the profile cannot take (Ajustes → Descarte automático):
# restricted to the US/Canada, to Europe or to a list of other countries, and, optionally,
# with a score below a minimum. Postings saved by hand (extension, manual) are never touched.
module AutoDismissal
  RESTRICTED = { "us_only" => "só EUA/Canadá", "europe_only" => "só Europa" }.freeze

  module_function

  def apply(posting, setting = Setting.current)
    return if JobPosting::MANUAL_SOURCES.include?(posting.source)

    reason = reason_for(posting, setting)
    posting.assign_attributes(triage: "dismissed", auto_dismissed_reason: reason) if reason
  end

  def reason_for(posting, setting)
    if setting.auto_dismiss_restricted?
      return RESTRICTED[posting.remote_scope] if RESTRICTED.key?(posting.remote_scope)
      return JobScorer::RESTRICTED_TERM if posting.matched_keywords.any? { it["term"] == JobScorer::RESTRICTED_TERM }
    end

    min = setting.auto_dismiss_below_score
    "nota abaixo de #{min}" if min && posting.score < min
  end
end
