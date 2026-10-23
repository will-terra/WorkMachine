module ProfilesHelper
  # The sentence that explains a suggestion of ProfileSuggestions, with its numbers.
  def suggestion_text(suggestion)
    reason =
      case suggestion.kind
      when "avoid" then suggestion.saved.zero? ? "avoid_none" : "avoid_few"
      when "promote" then suggestion.ratio ? "promote_answers" : "promote_saves"
      else "demote"
      end
    ratio = number_with_precision(suggestion.ratio, precision: 1, strip_insignificant_zeros: true) if suggestion.ratio
    t("profiles.suggestions.#{reason}", **suggestion.to_h.except(:kind, :level).merge(ratio:).compact)
  end
end
