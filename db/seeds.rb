# Idempotent: run `bin/rails db:seed` as many times as you want. Existing records are kept as they are,
# so edits made in the app (templates, consultancy registration) are never overwritten.

CONSULTANCIES = [
  [ "Yoctoo", "https://yoctoo.com/", "tech" ],
  [ "Hunter4Tech", "https://hunter4tech.com.br/", "tech" ],
  [ "Rehva Tech", "https://rehva.com.br/", "tech" ],
  [ "Huntz", "https://huntz.com.br/", "tech" ],
  [ "99Hunters", "https://99hunters.com/", "tech" ],
  [ "GeekHunter", "https://www.geekhunter.com.br/", "tech" ],
  [ "Intera", "https://www.byintera.com/", "tech" ],
  [ "Robert Half", "https://www.roberthalf.com/br/pt/procurando-oportunidade", "multinational", "Já anuncia vagas de Ruby on Rails." ],
  [ "Michael Page", "https://www.michaelpage.com.br/", "multinational" ],
  [ "Page Personnel", "https://www.pagepersonnel.com.br/", "multinational" ],
  [ "Hays", "https://www.hays.com.br/", "multinational" ],
  [ "Randstad", "https://www.randstad.com.br/", "multinational" ],
  [ "Adecco", "https://www.adecco.com.br/", "multinational" ],
  [ "ManpowerGroup", "https://www.manpowergroup.com.br/", "multinational" ],
  [ "Talenses", "https://www.talenses.com/", "multinational" ],
  [ "Gi Group", "https://www.gigroup.com.br/", "multinational" ]
].freeze

CONSULTANCIES.each do |name, url, kind, notes|
  Consultancy.find_or_create_by!(name:) do |consultancy|
    consultancy.url = url
    consultancy.kind = kind
    consultancy.notes = notes
  end
end

MESSAGE_TEMPLATES = [
  {
    name: "Conexão com recrutador (PT)", language: "pt", max_chars: 200,
    body: "Oi, {{nome}}! Sou Full Stack Ruby on Rails + React, com cerca de 3 anos de experiência e Rails 8.1 em produção. Vi que você recruta para tech e quero acompanhar as vagas da minha stack. Obrigado!"
  },
  {
    name: "Connection note (EN)", language: "en", max_chars: 200,
    body: "Hi {{nome}}! I'm a full-stack Ruby on Rails + React engineer (~3 yrs, Rails 8.1 in production) based in Brazil. I'd love to connect and follow your Rails openings. Thanks!"
  },
  {
    name: "Achei a vaga no post (PT)", language: "pt",
    body: "Oi, {{nome}}. Vi seu post sobre a vaga de {{cargo}} na {{empresa}}. Sou Full Stack com cerca de 3 anos em Ruby on Rails e React. Hoje lidero o upgrade de um ERP multi-tenant para Rails 8.1 e construí uma integração com Sidekiq que processa arquivos de até 50 MB. Achei a posição bem alinhada ao meu perfil. Posso te enviar meu currículo?"
  },
  {
    name: "Found your post (EN)", language: "en",
    body: "Hi {{nome}}, I saw your post about the {{cargo}} opening at {{empresa}}. I'm a full-stack engineer with about 3 years in Ruby on Rails and React. I'm currently leading a Rails 8.1 upgrade on a multi-tenant ERP, and before that I worked with an English-speaking team on Cliente E's front end. The role looks like a strong match. Could I send you my resume?"
  },
  {
    name: "Resposta a recrutador (PT)", language: "pt",
    body: "Oi, {{nome}}! Obrigado pelo contato. Tenho interesse na vaga de {{cargo}} na {{empresa}}. Hoje trabalho com Ruby on Rails 8.1, Hotwire e PostgreSQL num ERP multi-tenant, e antes atuei com React e Next.js num time que falava inglês. Qual é o melhor horário para conversarmos?"
  },
  {
    name: "Follow-up de candidatura (PT)", language: "pt",
    body: "Oi, {{nome}}! Tudo bem? Apliquei para a vaga de {{cargo}} na {{empresa}} há alguns dias e queria saber se há novidades no processo. Sigo bastante interessado e à disposição para conversar. Obrigado!"
  },
  {
    name: "Application follow-up (EN)", language: "en",
    body: "Hi {{nome}}, hope you're doing well. I applied for the {{cargo}} role at {{empresa}} a few days ago and wanted to check whether there are any updates. I'm still very interested and happy to talk anytime. Thanks!"
  }
].freeze

MESSAGE_TEMPLATES.each do |attributes|
  MessageTemplate.find_or_create_by!(name: attributes[:name]) do |template|
    template.assign_attributes(attributes)
  end
end

# Examples of companies that run Rails and publish their jobs on a public ATS board.
# They are marked as examples so you can tell them apart from the ones you add.
TARGET_COMPANIES = [
  [ "GitLab", "greenhouse", "gitlab" ],
  [ "Gusto", "greenhouse", "gusto" ],
  [ "Doximity", "greenhouse", "doximity" ],
  [ "Betterment", "greenhouse", "betterment" ],
  [ "Wealthsimple", "lever", "wealthsimple" ],
  [ "ezCater", "lever", "ezcater" ],
  [ "Kit (ConvertKit)", "ashby", "kit" ]
].freeze

TARGET_COMPANIES.each do |name, ats, board_slug|
  TargetCompany.find_or_create_by!(ats:, board_slug:) do |company|
    company.name = name
    company.example = true
  end
end

puts "Seeds: #{Consultancy.count} consultorias, #{MessageTemplate.count} modelos de mensagem, #{TargetCompany.count} empresas-alvo."
