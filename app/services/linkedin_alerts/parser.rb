module LinkedinAlerts
  # Reads the jobs out of a LinkedIn job alert e-mail. The layout of these e-mails changes
  # often, so the parser only relies on two things: links to /jobs/view/<id> and the text
  # around them. The HTML part is tried first; the plain-text part is the fallback.
  class Parser
    JOB_LINK = %r{linkedin\.com/(?:comm/)?jobs/view/(?:[^/?#"]*-)?(\d+)}i
    GENERIC_LINE = /\A(?:view job|ver vaga|see all jobs|see more jobs|ver todas as vagas|ver mais vagas|apply|apply now|candidatar-se|candidatura simplificada|easy apply|actively recruiting|recrutando agora|promoted|promovida|be an early applicant|seja um dos primeiros|new|nova|\d+ (?:applicants|candidaturas?|candidatos)|.*\b(?:alumni|ex-alunos?|connections?|conex(?:ão|ões)|school|escola)\b.*)\z/i
    MAX_FIELD = 200

    def self.call(html: nil, text: nil)
      new(html:, text:).call
    end

    def initialize(html:, text:)
      @html = html.to_s
      @text = text.to_s
    end

    def call
      jobs = @html.present? ? from_html : []
      jobs = from_text if jobs.empty? && @text.present?
      jobs.uniq { it[:url] }
    end

    private
      def from_html
        document = Nokogiri::HTML5(@html)
        anchors = document.css("a[href]").select { it["href"].match?(JOB_LINK) }

        anchors.group_by { it["href"][JOB_LINK, 1] }.filter_map do |job_id, links|
          title_link = title_link(links)
          next unless title_link

          title = text_lines(title_link).first
          details = card_lines(title_link, job_id) - [ title ]
          build(job_id, title, details)
        end
      end

      # The card is often one big link wrapping a smaller link on the title. The innermost link
      # with text is the title; a card link wraps the title, the company and the location.
      def title_link(links)
        candidates = links.select { |link| text_lines(link).any? }
        candidates.find { |link| link.css("a[href]").none? { it["href"].match?(JOB_LINK) } } || candidates.first
      end

      def text_lines(node)
        HtmlText.call(node.to_html).lines.map { clean(it) }.select { useful_line?(it) }
      end

      # Plain-text alerts list each job as "Title / Company / Location / View job: <url>", with
      # blank lines and lines such as "1 conexão" in between, and "----" between jobs.
      def from_text
        lines = @text.lines.map { clean(it) }
        lines.each_index.filter_map do |index|
          job_id = lines[index][JOB_LINK, 1] or next
          before = lines[0...index].reverse.take_while { !it.match?(/\A(?:-{3,}|={3,})|https?:\/\//) }.reverse
          before = before.select { useful_line?(it) }
          next if before.empty?

          build(job_id, before.first, before.drop(1))
        end
      end

      # Climbs from the title link to the largest block that only talks about this job.
      def card_lines(link, job_id)
        node = link
        while (parent = node.parent) && parent.element? && parent.name != "body"
          ids = parent.css("a[href]").filter_map { it["href"][JOB_LINK, 1] }.uniq
          break if ids != [ job_id ] || parent.text.length > 1500

          node = parent
        end
        text_lines(node)
      end

      def build(job_id, title, details)
        company, location = split_details(details)
        {
          title: title.truncate(MAX_FIELD),
          company: company&.truncate(MAX_FIELD),
          location_text: location&.truncate(MAX_FIELD),
          url: "https://www.linkedin.com/jobs/view/#{job_id}",
          external_id: job_id
        }
      end

      # "Acme · São Paulo, Brasil (Remoto)" or "Acme" followed by "São Paulo, Brasil".
      # LinkedIn separates company and location with "·"; company names may contain "|".
      def split_details(details)
        first, second = details
        return [ nil, nil ] if first.blank?

        company, location = first.split(/\s+·\s+/, 2)
        company, location = first.split(/\s+[•|]\s+/, 2) if location.nil?
        [ company, location.presence || second ]
      end

      def useful_line?(line)
        line.present? && !line.match?(GENERIC_LINE) && !line.match?(%r{\Ahttps?://}) && line.length <= 300
      end

      def clean(text)
        text.to_s.tr("\u00a0", " ").squish
      end
  end
end
