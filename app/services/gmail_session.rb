require "net/imap"

# A read-only IMAP session on Gmail (imap.gmail.com:993, SSL), with GMAIL_USER and an app
# password in GMAIL_APP_PASSWORD. The mailbox is opened with EXAMINE and messages must be read
# with BODY.PEEK, so nothing changes in the inbox.
module GmailSession
  HOST = "imap.gmail.com".freeze
  PORT = 993
  DEFAULT_FACTORY = -> { Net::IMAP.new(HOST, port: PORT, ssl: true) }

  class LoginError < StandardError; end

  module_function

  def configured?
    ENV["GMAIL_USER"].present? && ENV["GMAIL_APP_PASSWORD"].present?
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
    imap.login(ENV.fetch("GMAIL_USER"), ENV.fetch("GMAIL_APP_PASSWORD").delete(" "))
  rescue Net::IMAP::NoResponseError => e
    raise LoginError, login_hint(e.message)
  end

  def login_hint(message)
    if message.include?("Application-specific password required")
      "O Google exige uma senha de app: GMAIL_APP_PASSWORD deve ter as 16 letras geradas em " \
        "myaccount.google.com/apppasswords, não a senha da conta."
    else
      "O Gmail recusou o login (#{message.strip}). Confira GMAIL_USER e GMAIL_APP_PASSWORD."
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
