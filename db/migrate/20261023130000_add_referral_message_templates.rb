# The referral request templates of db/seeds.rb, for installations seeded before they existed.
class AddReferralMessageTemplates < ActiveRecord::Migration[8.1]
  TEMPLATES = [
    [ "Pedido de indicação (PT)", "pt",
      "Oi, {{nome}}! Tudo bem? Vi que a {{empresa}} está com a vaga de {{cargo}} aberta e quero me candidatar. Sou {{meu_resumo}} e trabalho com {{minha_stack}}. Você toparia me indicar ou me contar um pouco de como é o time? Posso te mandar meu currículo. Obrigado!" ],
    [ "Referral request (EN)", "en",
      "Hi {{nome}}! I noticed {{empresa}} is hiring for the {{cargo}} role and I'd love to apply. I'm a {{meu_resumo}}, working with {{minha_stack}}. Would you be open to referring me, or telling me a bit about the team? Happy to send my resume. Thanks!" ]
  ].freeze

  class Template < ActiveRecord::Base
    self.table_name = "message_templates"
  end

  def up
    return unless Template.exists? # a new database gets them from the seeds

    TEMPLATES.each do |name, language, body|
      Template.find_or_create_by!(name:) { it.assign_attributes(language:, body:) }
    end
  end

  def down
    Template.where(name: TEMPLATES.map(&:first)).delete_all
  end
end
