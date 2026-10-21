# Keys and accounts of this installation: the variable in .env when there is one, otherwise what
# was saved in Ajustes (Setting, encrypted in the database).
module AppKeys
  FIELDS = {
    openrouter_api_key: "OPENROUTER_API_KEY",
    openrouter_model: "OPENROUTER_MODEL",
    gmail_user: "GMAIL_USER",
    gmail_app_password: "GMAIL_APP_PASSWORD",
    api_token: "WORKMACHINE_API_TOKEN"
  }.freeze

  FIELDS.each do |field, variable|
    define_singleton_method(field) { ENV[variable].presence || saved(field) }
  end

  def self.from_env?(field)
    ENV[FIELDS.fetch(field)].present?
  end

  # A database copied without storage/workmachine-secrets.yml cannot be decrypted: the keys
  # then count as not saved, and Ajustes asks for them again.
  def self.saved(field)
    Setting.current.public_send(field).presence
  rescue ActiveRecord::Encryption::Errors::Decryption
    nil
  end
end
