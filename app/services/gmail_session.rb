require "net/imap"

# A read-only IMAP session on Gmail (imap.gmail.com:993, SSL), with the account and the app
# password from Ajustes (or GMAIL_USER and GMAIL_APP_PASSWORD in .env). The mailbox is opened
# with EXAMINE and messages must be read with BODY.PEEK, so nothing changes in the inbox.
module GmailSession
  HOST = "imap.gmail.com".freeze
  PORT = 993
  DEFAULT_FACTORY = -> { Net::IMAP.new(HOST, port: PORT, ssl: true) }

  class LoginError < StandardError; end

  module_function

  def configured?
    AppKeys.gmail_user.present? && AppKeys.gmail_app_password.present?
  end

  def mailbox
    ENV.fetch("GMAIL_MAILBOX", "INBOX")
  end

  def open(imap_factory = DEFAULT_FACTORY)
    imap = imap_factory.call
    login(imap)
    imap.examine(mailbox)
    yield imap
  ensure
    close(imap)
  end

  # Google shows app passwords in groups of four letters; the spaces are not part of it.
  def login(imap)
    imap.login(AppKeys.gmail_user, AppKeys.gmail_app_password.delete(" "))
  rescue Net::IMAP::NoResponseError => e
    raise LoginError, login_hint(e.message)
  end

  def login_hint(message)
    if message.include?("Application-specific password required")
      I18n.t("gmail.app_password_required")
    else
      I18n.t("gmail.login_refused", message: message.strip)
    end
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
