class MessageTemplate < ApplicationRecord
  PLACEHOLDERS = %w[nome cargo empresa].freeze
  PLACEHOLDER = /\{\{\s*(#{PLACEHOLDERS.join("|")})\s*\}\}/

  enum :language, { pt: "pt", en: "en" }, validate: true

  validates :name, :body, presence: true
  validates :name, uniqueness: true
  validates :max_chars, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  scope :ordered, -> { in_order_of(:language, %w[pt en]).order(:name) }

  # Replaces {{nome}}, {{cargo}} and {{empresa}}. Blank values keep the placeholder visible.
  def render(values = {})
    values = values.to_h.stringify_keys
    body.gsub(PLACEHOLDER) { values[$1].presence || "{{#{$1}}}" }
  end
end
