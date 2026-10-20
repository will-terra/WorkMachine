module LinkedinAlerts
  # Imports LinkedIn job alert e-mails from Gmail (GmailSession: read-only IMAP), searching
  # by sender since the last alert imported.
  class Importer
    DEFAULT_SENDERS = %w[jobalerts-noreply@linkedin.com jobs-noreply@linkedin.com].freeze
    FIRST_IMPORT_LOOKBACK = 14.days
    BATCH = 20

    Result = Data.define(:emails, :postings, :created)

    LoginError = GmailSession::LoginError

    def self.configured?
      GmailSession.configured?
    end

    def initialize(imap_factory: GmailSession::DEFAULT_FACTORY)
      @imap_factory = imap_factory
    end

    def call
      @emails = @postings = @created = 0
      GmailSession.open(@imap_factory) do |imap|
        imap.uid_search(search_keys).each_slice(BATCH) do |uids|
          Array(imap.uid_fetch(uids, "BODY.PEEK[]")).each { |data| import(data.attr["BODY[]"]) }
        end
      end

      Result.new(emails: @emails, postings: @postings, created: @created)
    end

    # Used by the import and by `bin/rails linkedin:parse[alerta.eml]`.
    def self.parse(raw)
      mail = Mail.new(raw)
      html = mail.html_part&.decoded || (mail.decoded if mail.mime_type == "text/html")
      text = mail.text_part&.decoded || (mail.decoded if mail.mime_type.in?([ nil, "text/plain" ]))
      [ mail, Parser.call(html:, text:) ]
    end

    private
      def import(raw)
        return if raw.blank?

        mail, jobs = self.class.parse(raw)
        message_id = mail.message_id.presence || Digest::SHA256.hexdigest(raw)
        return if ProcessedEmail.exists?(message_id:)

        received_at = mail.date&.to_time
        created = jobs.count { JobIngestor.call(it.merge(source: "linkedin_alert", posted_at: received_at)).created? }
        ProcessedEmail.create!(message_id:, subject: mail.subject.to_s.truncate(250), received_at:, postings_count: jobs.size)

        @emails += 1
        @postings += jobs.size
        @created += created
      end

      def search_keys
        last = ProcessedEmail.maximum(:received_at)
        since = last ? last.to_date - 1 : FIRST_IMPORT_LOOKBACK.ago.to_date
        senders = ENV.fetch("LINKEDIN_ALERT_SENDERS", DEFAULT_SENDERS.join(",")).split(",").map(&:strip).compact_blank
        from = senders.drop(1).reduce([ "FROM", senders.first ]) { |keys, sender| [ "OR", *keys, "FROM", sender ] }

        [ "SINCE", since.strftime("%d-%b-%Y"), *from ]
      end
  end
end
