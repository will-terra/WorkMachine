module MessageTemplatesHelper
  # The template's text in pieces: plain text, a filled placeholder (:filled) or one still empty
  # (:missing). The message controller does the same in the browser as the fields change.
  def message_segments(template, values, profile = Profile.current)
    filled = MessageTemplate.profile_values(profile, template.language).merge(values.to_h.stringify_keys)
    template.body.split(/(\{\{\s*\w+\s*\}\})/).compact_blank.map do |part|
      key = part[/\A\{\{\s*(\w+)\s*\}\}\z/, 1]
      next [ part, nil ] unless key

      filled[key].present? ? [ filled[key], :filled ] : [ part, :missing ]
    end
  end

  def message_segment_tag(text, kind)
    case kind
    when :filled then tag.span(text, class: "text-accent-text")
    when :missing then tag.span(text, class: "rounded-[2px] bg-warn-soft-2 text-warn-text")
    else text
    end
  end
end
