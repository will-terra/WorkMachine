# Language of the interface: Portuguese when the browser asks for any "pt" (pt-BR, pt-PT…), English
# otherwise, unless Ajustes → Idioma picks one. Without an Accept-Language header (scripts, tests)
# it is the default locale. Jobs and notifications use the language of the last visit.
class LocalePreference
  CHOICES = %w[auto pt-BR en].freeze

  def self.from_header(header)
    first = header.to_s.split(",").first.to_s.strip.downcase
    return I18n.default_locale if first.empty?

    first.start_with?("pt") ? :"pt-BR" : :en
  end

  # The locale of a request, remembering the detected one for the jobs.
  def self.for_request(header, setting = Setting.current)
    return setting.locale.to_sym unless setting.locale == "auto"

    detected = from_header(header)
    setting.update_column(:detected_locale, detected.to_s) if header.present? && setting.detected_locale != detected.to_s
    detected
  end

  # The locale of jobs and notifications, outside a request.
  def self.for_background(setting = Setting.current)
    locale = setting.locale == "auto" ? setting.detected_locale : setting.locale
    locale.presence_in(I18n.available_locales.map(&:to_s))&.to_sym || I18n.default_locale
  end
end
