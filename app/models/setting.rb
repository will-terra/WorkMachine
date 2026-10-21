# App-wide preferences (a single row): new-posting notifications and the Web Push (VAPID) keys.
class Setting < ApplicationRecord
  VAPID_SUBJECT = "https://github.com/will-terra/WorkMachine".freeze

  validates :notify_min_score, numericality: { only_integer: true, in: 0..100 }
  validates :auto_dismiss_below_score, numericality: { only_integer: true, in: 1..100 }, allow_nil: true

  def self.current
    first || create!
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

  # Generated on first use and kept in the database, so there is nothing to configure in .env.
  def vapid_keys!
    if vapid_public_key.blank? || vapid_private_key.blank?
      key = WebPush.generate_key
      update!(vapid_public_key: key.public_key, vapid_private_key: key.private_key)
    end
    { subject: VAPID_SUBJECT, public_key: vapid_public_key, private_key: vapid_private_key }
  end
end
