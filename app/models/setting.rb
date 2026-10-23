# App-wide preferences (a single row): notifications, sources, the Web Push (VAPID) keys and the
# keys and accounts typed in Ajustes (encrypted; see AppKeys).
class Setting < ApplicationRecord
  VAPID_SUBJECT = "https://github.com/will-terra/WorkMachine".freeze

  AI_PLANS = %w[free paid].freeze
  # "Buscar agora" runs at most once in this window.
  MANUAL_FETCH_COOLDOWN = 30.minutes

  enum :ai_plan, AI_PLANS.index_by(&:itself), prefix: true, validate: true
  encrypts :openrouter_api_key, :gmail_user, :gmail_app_password, :api_token
  normalizes :openrouter_api_key, :gmail_user, :api_token, :openrouter_model, with: ->(value) { value.strip.presence }
  normalizes :gmail_app_password, with: ->(value) { value.delete(" ").presence }

  validates :locale, inclusion: { in: LocalePreference::CHOICES }
  validates :notify_min_score, numericality: { only_integer: true, in: 0..100 }
  validates :auto_dismiss_below_score, numericality: { only_integer: true, in: 1..100 }, allow_nil: true

  def self.current
    first || create!
  end

  # The token the browser extension sends (Ajustes → Extensão do navegador).
  def regenerate_api_token!
    update!(api_token: SecureRandom.base58(40))
  end

  def onboarded?
    onboarded_at.present?
  end

  # When "Buscar agora" can run again, or nil when it can run now.
  def manual_fetch_available_at(now = Time.current)
    available_at = manual_fetch_at && manual_fetch_at + MANUAL_FETCH_COOLDOWN
    available_at if available_at&.after?(now)
  end

  def source_enabled?(key)
    !disabled_sources.include?(key.to_s)
  end

  # From the checkboxes of Ajustes → Fontes: an unchecked source is turned off. Sources that do
  # not match the profile are not on the form and keep their state.
  def enabled_sources=(keys)
    shown = Sources.all.select { it.applicable?(Profile.current) }.map(&:key)
    self.disabled_sources = (disabled_sources - shown) | (shown - Array(keys).map(&:to_s))
  end

  # Generated on first use and kept in the database, so there is nothing to configure.
  def vapid_keys!
    if vapid_public_key.blank? || vapid_private_key.blank?
      key = WebPush.generate_key
      update!(vapid_public_key: key.public_key, vapid_private_key: key.private_key)
    end
    { subject: VAPID_SUBJECT, public_key: vapid_public_key, private_key: vapid_private_key }
  end
end
