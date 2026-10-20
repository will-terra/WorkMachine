# Converts job description HTML into plain text, keeping paragraphs and list items.
# Descriptions are stored as text, so the app never renders third-party HTML.
module HtmlText
  BLOCKS = "p, div, tr, h1, h2, h3, h4, h5, h6, ul, ol, section, article, blockquote, table".freeze

  module_function

  def call(html)
    return "" if html.blank?

    fragment = Nokogiri::HTML5.fragment(fix_mojibake(html.to_s))
    fragment.css("script, style").each(&:remove)
    # Like a browser, source line breaks inside text are just spaces; structure comes from the tags.
    fragment.xpath(".//text()[not(ancestor::pre)]").each { |node| node.content = node.content.gsub(/\s+/, " ") }
    fragment.css("br").each { |node| node.replace("\n") }
    fragment.css("li").each do |node|
      node.prepend_child("• ")
      node.add_next_sibling("\n")
    end
    fragment.css(BLOCKS).each do |node|
      node.add_previous_sibling("\n")
      node.add_next_sibling("\n")
    end

    fragment.text
      .tr("\u00a0", " ")
      .gsub(/[ \t]+/, " ")
      .gsub(/ *\n */, "\n")
      .gsub(/\n{3,}/, "\n\n")
      .gsub(/•\s*\n+\s*/, "• ")
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
