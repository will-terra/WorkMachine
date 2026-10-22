module ApplicationReplies
  # Reads the replies of the companies you applied to from Gmail (read-only), classifies each
  # one (Classifier), moves the kanban card forward (rejection → Recusada, interview → Entrevista com IA, RH ou técnica,
  # test → Teste prático, offer → Proposta, a recruiter writing → Contato do recrutador) and
  # sends a notification. Only the headers of other e-mails are read.
  class Importer
    FIRST_LOOKBACK = 30.days
    BATCH = 200
    IGNORED_SENDERS = /\Ajobalerts-noreply@linkedin\.com\z/i
    TARGETS = { "rejection" => "rejected", "offer" => "offer", "assessment" => "take_home", "recruiter_contact" => "recruiter_contact" }.freeze
    INTERVIEW_TARGETS = { "ai" => "ai_interview", "technical" => "tech_interview", "hr" => "hr_interview" }.freeze
    # Order of the pipeline used to only move cards forward.
    PIPELINE = %w[saved applied no_response recruiter_contact ai_interview hr_interview tech_interview take_home offer].freeze
    LABELS = { "rejection" => "recusa", "interview" => "convite para entrevista", "assessment" => "teste",
               "offer" => "proposta", "recruiter_contact" => "mensagem do recrutador" }.freeze

    Result = Data.define(:matched, :moved)

    def initialize(imap_factory: GmailSession::DEFAULT_FACTORY, classifier: Classifier.new)
      @imap_factory = imap_factory
      @classifier = classifier
    end

    def call
      matcher = Matcher.new
      @matched = @moved = 0
      started_at = Time.current

      GmailSession.open(@imap_factory) do |imap|
        imap.uid_search([ "SINCE", since.strftime("%d-%b-%Y") ]).each_slice(BATCH) do |uids|
          Array(imap.uid_fetch(uids, %w[UID ENVELOPE])).each { |data| read(imap, data, matcher) }
        end
      end

      Setting.current.update!(replies_checked_at: started_at)
      Result.new(matched: @matched, moved: @moved)
    end

    private
      def since
        last = Setting.current.replies_checked_at
        last ? last.to_date - 1 : FIRST_LOOKBACK.ago.to_date
      end

      def read(imap, data, matcher)
        envelope = data.attr["ENVELOPE"]
        message_id = envelope.message_id.to_s.delete("<>").strip
        return if message_id.empty? || ApplicationEmail.exists?(message_id:)

        sender = Array(envelope.from).first
        from_address = [ sender&.mailbox, sender&.host ].compact.join("@")
        return if from_address.match?(IGNORED_SENDERS) || from_address.casecmp?(AppKeys.gmail_user.to_s)

        from_name = decode(sender&.name)
        subject = decode(envelope.subject)
        application = matcher.match(from_name:, from_address:, subject:) or return

        body = text_of(imap.uid_fetch(data.attr["UID"], "BODY.PEEK[]")&.first&.attr&.dig("BODY[]"))
        record(application, message_id:, from_name:, from_address:, subject:, body:, received_at: parse_date(envelope.date))
      end

      def record(application, message_id:, from_name:, from_address:, subject:, body:, received_at:)
        result = @classifier.call(application:, from: "#{from_name} <#{from_address}>", subject:, body:)
        status_before = application.status
        moved = result.category.in?(ApplicationEmail::ANSWERS) && move(application, result, received_at)

        ApplicationEmail.create!(job_application: application, message_id:, from_name:, from_address:, subject: subject.to_s.truncate(250),
                                 received_at:, category: result.category, summary: result.summary, classified_by: result.classified_by,
                                 status_before:, status_after: application.status)
        return if result.category == "unrelated"

        @matched += 1
        @moved += 1 if moved
        notify(application, result) if result.category.in?(ApplicationEmail::ANSWERS)
      end

      def move(application, result, received_at)
        target = result.category == "interview" ? INTERVIEW_TARGETS.fetch(result.interview_type, "hr_interview") : TARGETS.fetch(result.category)
        application.responded_on ||= (received_at || Time.current).to_date
        application.next_follow_up_on = nil
        unless forward?(application.status, target)
          application.save!
          return false
        end

        application.move_to!(target, JobApplication.where(status: target).count)
        true
      end

      def forward?(current, target)
        return false if current == target || %w[rejected withdrawn].include?(current)
        return true if target == "rejected"

        PIPELINE.index(target).to_i > PIPELINE.index(current).to_i
      end

      def notify(application, result)
        setting = Setting.current
        return unless setting.notify_replies?

        PushSender.deliver_all(title: "#{application.company}: #{LABELS.fetch(result.category)}",
                               body: result.summary.presence || application.role, path: "/candidaturas/#{application.id}/edit",
                               tag: "reply-#{application.id}")
      end

      def text_of(raw)
        return "" if raw.blank?

        mail = Mail.new(raw)
        text = mail.text_part&.decoded.presence
        text ||= HtmlText.call(mail.html_part.decoded) if mail.html_part
        text ||= mail.mime_type == "text/html" ? HtmlText.call(mail.decoded) : mail.decoded
        text.to_s
      rescue Mail::Field::ParseError, ArgumentError
        ""
      end

      def decode(value)
        Mail::Encodings.value_decode(value.to_s).strip
      end

      def parse_date(value)
        Time.zone.parse(value.to_s)
      rescue ArgumentError
        nil
      end
  end
end
