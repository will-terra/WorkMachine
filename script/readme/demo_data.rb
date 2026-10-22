# Fictional data for the README screenshots (script/readme/screenshots.mjs). Wipes the
# DEVELOPMENT database and fills it with a made-up person, companies and postings:
#
#   bin/rails db:reset && bin/rails runner script/readme/demo_data.rb
#
# Never run it against a real installation.
abort "Só no banco de desenvolvimento." unless Rails.env.development?

today = Date.current
now = Time.current

User.first || User.create!(email_address: "demo@workmachine.local", password: "workmachine", password_confirmation: "workmachine")
Setting.current.update!(onboarded_at: now, replies_checked_at: 40.minutes.ago, last_backup_at: 20.minutes.ago,
                        gmail_user: "ana.exemplo@gmail.com", gmail_app_password: "abcdabcdabcdabcd")
3.times { |index| ProcessedEmail.create!(message_id: "alerta-#{index}@exemplo.com", subject: "Vagas de Ruby on Rails", received_at: (index * 8).hours.ago, postings_count: 4 + index) }

Profile.current.update!(
  name: "Ana Ribeiro", headline: "Desenvolvedora Back-end Ruby on Rails", location: "Belo Horizonte, MG, Brasil",
  languages: "Português nativo, inglês avançado", github_url: "https://github.com/exemplo",
  primary_area: "backend", plan_b_area: "fullstack", seniority: "senior", years_experience: 7,
  target_titles: [ "Desenvolvedora Ruby", "Engenheira de Software Back-end" ],
  target_titles_en: [ "Rails Engineer", "Backend Engineer", "Ruby Developer" ],
  work_modes: %w[remote], regions: %w[brazil latam worldwide], salary_brl_min: 14_000, salary_brl_max: 19_000,
  salary_usd_min: 4_500, salary_usd_max: 7_000,
  skills: [
    { "name" => "Ruby", "level" => "essential" }, { "name" => "Rails", "level" => "essential", "synonyms" => [ "Ruby on Rails" ] },
    { "name" => "PostgreSQL", "level" => "important", "synonyms" => [ "Postgres" ] }, { "name" => "Sidekiq", "level" => "important" },
    { "name" => "Redis", "level" => "important" }, { "name" => "RSpec", "level" => "important" }, { "name" => "Hotwire", "level" => "important" },
    { "name" => "Docker", "level" => "extra" }, { "name" => "AWS", "level" => "extra" }, { "name" => "GraphQL", "level" => "extra" },
    { "name" => "React", "level" => "extra" }
  ],
  avoid_terms: [ "PHP", "presencial" ], search_terms: [ "Rails", "Ruby" ], plan_b_terms: [ "React", "TypeScript" ],
  ai_profile: "7 anos com Ruby on Rails em fintechs e SaaS B2B. APIs, filas com Sidekiq, PostgreSQL, testes com RSpec."
)

ago = ->(hours) { now - hours.hours }
postings = [
  [ "Senior Ruby on Rails Engineer", "Lumen Pay", :remotive, "Remote · LATAM", 3, "US$ 6.000–7.500/mês", "Senior Ruby on Rails engineer. PostgreSQL, Sidekiq, Redis and RSpec. Remote for Latin America, 5+ years." ],
  [ "Engenheira de Software Back-end (Rails)", "Lumi Crédito", :linkedin_alert, "Remoto · Brasil", 5, "R$ 16.000–19.000", "Ruby on Rails e PostgreSQL. Remoto para todo o Brasil. Sênior." ],
  [ "Rails Developer", "Pomar Tech", :we_work_remotely, "Anywhere", 8, nil, "Rails and Docker. Fully remote, worldwide." ],
  [ "Desenvolvedor Ruby", "Brisa Educação", :remotar, "Remoto · Brasil", 10, "R$ 12.000", "Ruby, GraphQL e AWS. Remoto." ],
  [ "Full Stack Engineer (Rails + React)", "Sabiá Mídia", :himalayas, "Remote · LATAM", 14, "US$ 5.000/mês", "Ruby on Rails and React. Remote in LATAM." ],
  [ "Software Engineer II, Platform", "Atlas Cloud", :lever, "Remote · Brazil", 20, nil, "Go services, Kubernetes and AWS, some Ruby. Remote in Brazil." ],
  [ "Backend Engineer (Node.js)", "Maré Energia", :remote_ok, "Remote", 26, nil, "Node.js, TypeScript, PostgreSQL. Remote." ],
  [ "Senior Backend Engineer (Python)", "Ipê Analytics", :hacker_news, "Remote", 33, nil, "Python, Django, Postgres. Remote." ],
  [ "Desenvolvedor PHP Sênior", "Rio Verde Agro", :backend_br, "Remoto · Brasil", 40, nil, "PHP, Laravel, MySQL. Remoto." ],
  [ "Staff Engineer", "Tecla", :ashby, "Remote · US only", 50, "US$ 180k/ano", "Ruby on Rails, PostgreSQL. Must be located in the US." ],
  [ "Engenheiro de Dados", "Faro Mobilidade", :linkedin_alert, "Híbrido · Goiânia", 60, nil, "Python, Spark, Airflow. Híbrido em Goiânia." ]
]
created = postings.map do |title, company, source, location, hours, salary, description|
  JobIngestor.call(title:, company:, source: source.to_s, url: "https://vagas.exemplo.com/#{company.parameterize}/#{title.parameterize}",
                   location_text: location, posted_at: ago.(hours), salary_text: salary, description:).posting.tap { it.update_columns(created_at: ago.(hours)) }
end
created.find { it.company == "Faro Mobilidade" }.update!(triage: "dismissed")

AiArtifact.create!(job_posting: created.first, kind: "fit_analysis", status: "completed", model: "minimax/minimax-m3.1-flash:free", content: <<~TEXT.strip)
  Fit alto (8/10). A vaga pede exatamente o seu núcleo: Rails, PostgreSQL, Sidekiq e Redis, com 5+ anos.
  Pontos fortes: filas com Sidekiq e testes com RSpec aparecem no seu perfil.
  Atenção: a vaga cita Kafka de passagem; vale dizer na conversa que você já integrou filas assíncronas.
TEXT

applications = [
  [ "Ferro Digital", "Ruby Engineer", "saved", nil, nil ],
  [ "Orbitas", "Rails Developer", "saved", nil, nil ],
  [ "Vértice", "Rails Developer", "applied", 2, nil ],
  [ "Trilha Seguros", "Pessoa Desenvolvedora Back-end", "applied", 7, today ],
  [ "Ponte Fintech", "Ruby Engineer", "applied", 9, today ],
  [ "Cobalto", "Software Engineer II", "applied", 4, nil ],
  [ "Caju Bank", "Engenheira de Software Back-end", "recruiter_contact", 6, today + 2 ],
  [ "Nimbus Labs", "Backend Engineer, Payments", "ai_interview", 8, nil ],
  [ "Vela Saúde", "Desenvolvedor Ruby Sênior", "hr_interview", 12, nil ],
  [ "Kora Commerce", "Full Stack Engineer", "tech_interview", 15, nil ],
  [ "Quanta Logística", "Rails Engineer", "take_home", 18, nil ],
  [ "Faro Mobilidade", "Backend Engineer", "offer", 25, nil ],
  [ "Zinco", "Desenvolvedora Back-end", "rejected", 20, nil ],
  [ "Lince", "Desenvolvedor PHP", "withdrawn", 30, nil ],
  [ "Atrio", "Ruby Developer", "no_response", 35, nil ],
  [ "Nexo Saúde", "Backend Engineer", "saved", nil, nil ],
  [ "Dobra", "Rails Engineer", "saved", nil, nil ],
  [ "Tangram", "Desenvolvedora Ruby", "applied", 1, nil ],
  [ "Plano Alto", "Backend Developer", "applied", 3, nil ],
  [ "Granito", "Ruby on Rails Developer", "applied", 5, nil ],
  [ "Cais", "Software Engineer", "applied", 6, nil ],
  [ "Aurora Pagamentos", "Senior Rails Engineer", "recruiter_contact", 4, nil ],
  [ "Eixo", "Backend Engineer", "hr_interview", 10, nil ],
  [ "Prumo", "Engenheira Back-end", "rejected", 16, nil ]
].map do |company, role, status, days, follow_up|
  JobApplication.create!(company:, role:, status:, origin: %w[LinkedIn Remotar Greenhouse Indicação Gupy].sample(random: Random.new(company.sum)),
                         applied_on: days && today - days, next_follow_up_on: follow_up, contact_url: "https://vagas.exemplo.com/#{company.parameterize}")
end

[
  [ "Nimbus Labs", "interview", "Convite para uma entrevista gravada em vídeo com IA (HireVue), com prazo de 5 dias.", "applied", "ai_interview", 3 ],
  [ "Vela Saúde", "interview", "A recrutadora quer marcar a entrevista com o RH na quinta.", "applied", "hr_interview", 20 ],
  [ "Quanta Logística", "assessment", "Desafio técnico: uma API Rails com prazo de uma semana.", "tech_interview", "take_home", 26 ],
  [ "Zinco", "rejection", "Seguiram com outra pessoa nesta vaga e pedem para manter contato.", "applied", "rejected", 30 ]
].each do |company, category, summary, before, after, hours|
  application = applications.find { it.company == company }
  ApplicationEmail.create!(job_application: application, message_id: "demo-#{company.parameterize}@exemplo.com", from_name: "Recrutamento #{company}",
                           from_address: "talentos@#{company.parameterize}.exemplo.com", subject: "Sua candidatura na #{company}", received_at: ago.(hours),
                           category:, summary:, status_before: before, status_after: after, classified_by: "ai")
end

[
  [ "Mariana Costa", "Tech Recruiter · fintechs", "Caju Bank", "recruiter", 2 ],
  [ "Rafael Souza", "Engineering Manager", "Kora Commerce", "manager", 9 ],
  [ "Juliana Prado", "Talent Acquisition LATAM", "Nimbus Labs", "recruiter", 4 ],
  [ "Pedro Almeida", "Head de Engenharia", "Vela Saúde", "manager", 45 ],
  [ "Camila Torres", "Recrutadora tech", "Yoctoo", "recruiter", nil ]
].each_with_index do |(name, headline, company, kind, days), index|
  Contact.create!(name:, headline:, company:, kind:, last_contacted_on: days && today - days, linkedin_url: "https://www.linkedin.com/in/exemplo-#{index}")
end

TargetCompany.where(example: true).update_all(last_fetched_at: 2.hours.ago)
TargetCompany.create!(name: "Lumen Pay", ats: "greenhouse", board_slug: "lumenpay-exemplo", active: false, discovered_at: now, discovered_from: created.first)
TargetCompany.create!(name: "Pomar Tech", ats: "ashby", board_slug: "kora-exemplo", active: false, discovered_at: now)

(JobPosting::SOURCES - %w[extension manual]).each_with_index do |source, index|
  run = SourceRun.create!(source:, status: "succeeded", fetched_count: 20 + index * 3, created_count: index % 4, created_at: (index * 7).minutes.ago, finished_at: (index * 7).minutes.ago)
  run.update!(status: "failed", error_message: "HTTP 503 do servidor da fonte") if source == "working_nomads"
end

Consultancy.order(:id).limit(4).each { it.update!(registered_on: today - 10) }
%w[m1 m2 m4 a1].each { Routine.toggle!(it) }
%w[s1 s2 s3 s4 s5 s6 s7 s8 s9 s10].each { Routine.toggle!(it) }

puts "Dados de demonstração prontos: #{JobPosting.count} vagas, #{JobApplication.count} candidaturas."
