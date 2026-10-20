require "net/imap"

module LinkedinAlerts
  # Imports LinkedIn job alert e-mails from Gmail over IMAP (imap.gmail.com:993, SSL),
  # with GMAIL_USER and an app password in GMAIL_APP_PASSWORD. The mailbox is opened
  # read-only and messages are fetched with BODY.PEEK, so nothing changes in the inbox.
  class Importer
    HOST = "imap.gmail.com".freeze
    PORT = 993
    DEFAULT_SENDERS = %w[jobalerts-noreply@linkedin.com jobs-noreply@linkedin.com].freeze
    FIRST_IMPORT_LOOKBACK = 14.days
    BATCH = 20

    Result = Data.define(:emails, :postings, :created)

    def self.configured?
      ENV["GMAIL_USER"].present? && ENV["GMAIL_APP_PASSWORD"].present?
    end

    def initialize(imap_factory: -> { Net::IMAP.new(HOST, port: PORT, ssl: true) })
      @imap_factory = imap_factory
    end

    def call
      @emails = @postings = @created = 0
      imap = @imap_factory.call
      imap.login(ENV.fetch("GMAIL_USER"), ENV.fetch("GMAIL_APP_PASSWORD"))
      imap.examine(mailbox)

      imap.uid_search(search_keys).each_slice(BATCH) do |uids|
        Array(imap.uid_fetch(uids, "BODY.PEEK[]")).each { |data| import(data.attr["BODY[]"]) }
      end

      Result.new(emails: @emails, postings: @postings, created: @created)
    ensure
      close(imap)
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

      def mailbox
        ENV.fetch("GMAIL_MAILBOX", "INBOX")
      end

      def close(imap)
        return unless imap

        imap.logout unless imap.disconnected?
      rescue Net::IMAP::Error, IOError, SystemCallError
        nil
      ensure
        imap.disconnect unless imap.disconnected?
      end
  end
end
