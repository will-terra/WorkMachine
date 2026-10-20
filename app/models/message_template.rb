class MessageTemplate < ApplicationRecord
  PLACEHOLDERS = %w[nome cargo empresa].freeze
  PLACEHOLDER = /\{\{\s*(#{PLACEHOLDERS.join("|")})\s*\}\}/

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

  # Replaces {{nome}}, {{cargo}} and {{empresa}}. Blank values keep the placeholder visible.
  def render(values = {})
    values = values.to_h.stringify_keys
    body.gsub(PLACEHOLDER) { values[$1].presence || "{{#{$1}}}" }
  end
end
