# Keeps only the job description from the text of a LinkedIn job page. When LinkedIn changes its
# layout, the extension falls back to the whole page: top card, Premium ads, the company box,
# "More jobs", footer and the language list. The description sits between "About the job" and
# the "Set alert for similar jobs" box (headings in English, Portuguese and Spanish).
module LinkedinJobText
  START = /\A(?:about the job|sobre a vaga|acerca del empleo)\z/i
  ALERT = /\A(?:set alert for similar jobs|ative um alerta para vagas semelhantes|crea una alerta para empleos similares)\z/i
  # Without the alert box, the next LinkedIn heading. Exact case, because descriptions often have
  # their own "About The Company".
  NEXT_BOX = /\A(?:About the company|Sobre a empresa|Acerca de la empresa|More jobs|Mais vagas|Más empleos)\z/
  # The "see more" / "see less" buttons around the description.
  BUTTONS = /\A(?:(?:…|\.\.\.)\s*(?:more|mais|más)|show less|exibir menos|mostrar menos|ver menos)\z/i
  # The page footer: whole page saved before the description loaded.
  FOOTER = /^\s*LinkedIn Corporation ©/

  module_function

  def call(text)
    lines = text.to_s.lines(chomp: true)
    start = lines.index { |line| line.strip.match?(START) }
    return (text unless text.to_s.match?(FOOTER)) if start.nil?

    body = lines.drop(start + 1)
    finish = body.index { |line| line.strip.match?(ALERT) } || body.index { |line| line.strip.match?(NEXT_BOX) }
    body = body.first(finish) if finish
    body.reject { |line| line.strip.match?(BUTTONS) }.join("\n").gsub(/\n{3,}/, "\n\n").strip
  end

  def linkedin?(url)
    URI.parse(url.to_s).host.to_s.match?(/(\A|\.)linkedin\.com\z/)
  rescue URI::InvalidURIError
    false
  end
end
