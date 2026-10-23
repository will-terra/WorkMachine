class MessageTemplate < ApplicationRecord
  PLACEHOLDERS = %w[nome cargo empresa].freeze
  PLACEHOLDER = /\{\{\s*(#{PLACEHOLDERS.join("|")})\s*\}\}/
  # Filled from the profile, in the template's language.
  PROFILE_PLACEHOLDERS = %w[meu_resumo minha_stack].freeze
  PROFILE_PLACEHOLDER = /\{\{\s*(#{PROFILE_PLACEHOLDERS.join("|")})\s*\}\}/

  enum :language, { pt: "pt", en: "en" }, validate: true

  validates :name, :body, presence: true
  validates :name, uniqueness: true
  validates :max_chars, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :ordered, -> { in_order_of(:language, %w[pt en]).order(:name) }

  # The follow-up template of the seeds (db/seeds.rb), in Portuguese first.
  def self.follow_up
    where("name LIKE ?", "%ollow-up%").in_order_of(:language, %w[pt en]).first
  end

  # Mensagens filled with the application, scrolled to the follow-up template.
  def self.follow_up_path(application)
    template = follow_up
    path = Rails.application.routes.url_helpers.message_templates_path(job_application_id: application.id)
    template ? "#{path}#message_template_#{template.id}" : path
  end

  # The referral request of the seeds, in the interface language first.
  def self.referral
    languages = I18n.locale.to_s.start_with?("pt") ? %w[pt en] : %w[en pt]
    where("name LIKE ? OR name LIKE ?", "%indicação%", "%eferral%").in_order_of(:language, languages).first
  end

  # What Contatos → Mensagem opens: the connection note for a recruiter, "found your post" for a manager.
  def self.for_contact(contact)
    ordered.where("name LIKE ?", contact.recruiter? ? "%recrutador%" : "%post%").first
  end

  # Replaces {{nome}}, {{cargo}} and {{empresa}}. Blank values keep the placeholder visible.
  def render(values = {}, profile = Profile.current)
    values = values.to_h.stringify_keys
    body_for(profile).gsub(PLACEHOLDER) { values[$1].presence || "{{#{$1}}}" }
  end

  # The body with {{meu_resumo}} and {{minha_stack}} written from the profile.
  def body_for(profile = Profile.current)
    values = self.class.profile_values(profile, language)
    body.gsub(PROFILE_PLACEHOLDER) { values[$1].presence || "{{#{$1}}}" }
  end

  # "Full Stack Engineer, com cerca de 3 anos de experiência" and "Rails, Ruby e React".
  def self.profile_values(profile, language)
    english = language.to_s == "en"
    years = profile.years_experience
    experience = if years.to_i.positive?
      english ? " with about #{years} years of experience" : ", com cerca de #{years} anos de experiência"
    end
    skills = (profile.skills_at("essential") + profile.skills_at("important")).map { it["name"] }.first(4)
    {
      "meu_resumo" => ("#{profile.headline}#{experience}" if profile.headline.present?),
      "minha_stack" => skills.to_sentence(english ? { words_connector: ", ", two_words_connector: " and ", last_word_connector: ", and " } : { words_connector: ", ", two_words_connector: " e ", last_word_connector: " e " })
    }
  end
end
