# Converts job description HTML into plain text, keeping paragraphs and list items.
# Descriptions are stored as text, so the app never renders third-party HTML.
module HtmlText
  BLOCKS = "p, div, li, tr, h1, h2, h3, h4, h5, h6, ul, ol, section, article, blockquote".freeze

  module_function

  def call(html)
    return "" if html.blank?

    fragment = Nokogiri::HTML5.fragment(fix_mojibake(html.to_s))
    fragment.css("script, style").each(&:remove)
    fragment.css("br").each { |node| node.replace("\n") }
    fragment.css("li").each { |node| node.prepend_child("• ") }
    fragment.css(BLOCKS).each { |node| node.add_next_sibling("\n") }

    fragment.text
      .tr(" ", " ")
      .gsub(/[ \t]+/, " ")
      .gsub(/ *\n */, "\n")
      .gsub(/\n{3,}/, "\n\n")
      .strip
  end

  # Some feeds (Remote OK) send UTF-8 that was decoded as Latin-1 ("â\u0080\u0094" for "—").
  # C1 control characters never appear in real text, so they flag the problem.
  def fix_mojibake(text)
    return text unless text.match?(/[\u0080-\u009f]/)

    repaired = text.encode(Encoding::ISO_8859_1).force_encoding(Encoding::UTF_8)
    repaired.valid_encoding? ? repaired : text
  rescue EncodingError
    text
  end
end
