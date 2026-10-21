# Idempotent: run `bin/rails db:seed` as many times as you want. Existing records are kept as they are,
# so edits made in the app (templates, consultancy registration) are never overwritten.

# Platforms that work by profile, and recruiting consultancies: a checklist on the Radar.
consultancies = [
  [ "RailsDevs", "https://railsdevs.com/", "platform", "Para quem é de Rails: as empresas entram em contato." ],
  [ "Turing", "https://www.turing.com/jobs", "platform", "Empresas dos EUA; pede 3+ anos, inglês fluente e 4 h de sobreposição de fuso." ],
  [ "Strider", "https://www.onstrider.com/", "platform", "Devs da América Latina para empresas americanas; tem avaliações." ],
  [ "Revelo", "https://www.revelo.com/", "platform", "Vagas internacionais para brasileiros; boa referência de salário em dólar." ],
  [ "Wellfound", "https://www.wellfound.com/", "platform", "Startups do mundo todo." ],
  [ "Welcome to the Jungle (Otta)", "https://www.welcometothejungle.com/", "platform", "Startups do Reino Unido e da Europa." ],
  [ "Gupy", "https://portal.gupy.io/", "platform", "Mantenha o cadastro completo: empresas grandes filtram por lá." ],
  [ "InHire", "https://www.inhire.com.br/", "platform", "Usado por muitas empresas de tech brasileiras." ],
  [ "Yellow.rec", "https://www.yellow.rec.br/", "platform" ],
  [ "99jobs", "https://www.99jobs.com/", "platform" ],
  [ "Yoctoo", "https://yoctoo.com/", "tech" ],
  [ "Hunter4Tech", "https://hunter4tech.com.br/", "tech" ],
  [ "Rehva Tech", "https://rehva.com.br/", "tech" ],
  [ "Huntz", "https://huntz.com.br/", "tech" ],
  [ "99Hunters", "https://99hunters.com/", "tech" ],
  [ "GeekHunter", "https://www.geekhunter.com.br/", "tech" ],
  [ "Intera", "https://www.byintera.com/", "tech" ],
  [ "Robert Half", "https://www.roberthalf.com/br/pt/procurando-oportunidade", "multinational", "Anuncia vagas de tecnologia." ],
  [ "Michael Page", "https://www.michaelpage.com.br/", "multinational" ],
  [ "Page Personnel", "https://www.pagepersonnel.com.br/", "multinational" ],
  [ "Hays", "https://www.hays.com.br/", "multinational" ],
  [ "Randstad", "https://www.randstad.com.br/", "multinational" ],
  [ "Adecco", "https://www.adecco.com.br/", "multinational" ],
  [ "ManpowerGroup", "https://www.manpowergroup.com.br/", "multinational" ],
  [ "Talenses", "https://www.talenses.com/", "multinational" ],
  [ "Gi Group", "https://www.gigroup.com.br/", "multinational" ]
].freeze

consultancies.each do |name, url, kind, notes|
  Consultancy.find_or_create_by!(name:) do |consultancy|
    consultancy.url = url
    consultancy.kind = kind
    consultancy.notes = notes
  end
end

message_templates = [
  {
    name: "Conexão com recrutador (PT)", language: "pt", max_chars: 200,
    body: "Oi, {{nome}}! Sou {{meu_resumo}}. Vi que você recruta para tech e quero acompanhar as vagas da minha área. Obrigado!"
  },
  {
    name: "Connection note (EN)", language: "en", max_chars: 200,
    body: "Hi {{nome}}! I'm a {{meu_resumo}} based in Brazil. I'd love to connect and follow your openings. Thanks!"
  },
  {
    name: "Achei a vaga no post (PT)", language: "pt",
    body: "Oi, {{nome}}. Vi seu post sobre a vaga de {{cargo}} na {{empresa}}. Sou {{meu_resumo}} e trabalho com {{minha_stack}}. Achei a posição bem alinhada ao meu perfil. Posso te enviar meu currículo?"
  },
  {
    name: "Found your post (EN)", language: "en",
    body: "Hi {{nome}}, I saw your post about the {{cargo}} opening at {{empresa}}. I'm a {{meu_resumo}}, working with {{minha_stack}}. The role looks like a strong match. Could I send you my resume?"
  },
  {
    name: "Resposta a recrutador (PT)", language: "pt",
    body: "Oi, {{nome}}! Obrigado pelo contato. Tenho interesse na vaga de {{cargo}} na {{empresa}}. Sou {{meu_resumo}} e trabalho com {{minha_stack}}. Qual é o melhor horário para conversarmos?"
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

message_templates.each do |attributes|
  MessageTemplate.find_or_create_by!(name: attributes[:name]) do |template|
    template.assign_attributes(attributes)
  end
end

# Examples of tech companies that publish their jobs on a public ATS board (many roles: development,
# data, design, product…). The aggregator keeps only the titles of the profile's areas.
# They are marked as examples so you can tell them apart from the ones you add.
target_companies = [
  [ "GitLab", "greenhouse", "gitlab" ],
  [ "Gusto", "greenhouse", "gusto" ],
  [ "Doximity", "greenhouse", "doximity" ],
  [ "Betterment", "greenhouse", "betterment" ],
  [ "Wealthsimple", "lever", "wealthsimple" ],
  [ "ezCater", "lever", "ezcater" ],
  [ "Kit (ConvertKit)", "ashby", "kit" ]
].freeze

target_companies.each do |name, ats, board_slug|
  TargetCompany.find_or_create_by!(ats:, board_slug:) do |company|
    company.name = name
    company.example = true
  end
end

puts "Seeds: #{Consultancy.count} consultorias, #{MessageTemplate.count} modelos de mensagem, #{TargetCompany.count} empresas-alvo."
