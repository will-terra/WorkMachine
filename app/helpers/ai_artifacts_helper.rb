module AiArtifactsHelper
  # The tailored CV's Markdown (# name, ## sections, ### jobs, "- " bullets) as HTML, escaped.
  def cv_html(text)
    blocks = []
    bullets = []
    flush = -> { blocks << tag.ul(safe_join(bullets.map { tag.li(it) })) if bullets.any?; bullets = [] }

    text.to_s.each_line do |line|
      line = line.strip.gsub(/\*\*(.+?)\*\*/, '\1')
      next flush.call if line.empty?

      if (bullet = line[/\A[-•*]\s+(.*)\z/, 1]) then bullets << bullet
      else
        flush.call
        level = line[/\A(#+)\s/, 1]&.size
        blocks << (level ? content_tag(:"h#{level.clamp(1, 3)}", line.sub(/\A#+\s+/, "")) : tag.p(line))
      end
    end
    flush.call
    safe_join(blocks)
  end
end
