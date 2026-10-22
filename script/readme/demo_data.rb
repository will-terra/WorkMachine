# Fictional data for the README screenshots (script/readme/screenshots.mjs). Wipes the
# DEVELOPMENT database and fills it with a made-up person, companies and postings, in Portuguese
# or, with DEMO_LOCALE=en, in English (for README.md):
#
#   bin/rails db:reset && bin/rails runner script/readme/demo_data.rb
#   bin/rails db:reset && DEMO_LOCALE=en bin/rails runner script/readme/demo_data.rb
#
# Never run it against a real installation.
abort "Só no banco de desenvolvimento." unless Rails.env.development?

english = ENV["DEMO_LOCALE"] == "en"
tr = ->(portuguese, in_english) { english ? in_english : portuguese }
today = Date.current
now = Time.current

User.first || User.create!(email_address: "demo@workmachine.local", password: "workmachine", password_confirmation: "workmachine")
Setting.current.update!(onboarded_at: now, replies_checked_at: 40.minutes.ago, last_backup_at: 20.minutes.ago,
                        gmail_user: "ana.exemplo@gmail.com", gmail_app_password: "abcdabcdabcdabcd")
3.times { |index| ProcessedEmail.create!(message_id: "alerta-#{index}@exemplo.com", subject: tr.("Vagas de Ruby on Rails", "Ruby on Rails jobs"), received_at: (index * 8).hours.ago, postings_count: 4 + index) }

Profile.current.update!(
  name: "Ana Ribeiro", headline: tr.("Desenvolvedora Back-end Ruby on Rails", "Backend Engineer, Ruby on Rails"), location: tr.("Belo Horizonte, MG, Brasil", "Belo Horizonte, Brazil"),
  languages: tr.("Português nativo, inglês avançado", "Portuguese (native), English (advanced)"), github_url: "https://github.com/exemplo",
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
  avoid_terms: [ "PHP", tr.("presencial", "on-site") ], search_terms: [ "Rails", "Ruby" ], plan_b_terms: [ "React", "TypeScript" ],
  ai_profile: tr.("7 anos com Ruby on Rails em fintechs e SaaS B2B. APIs, filas com Sidekiq, PostgreSQL, testes com RSpec.",
                  "7 years of Ruby on Rails at fintechs and B2B SaaS. APIs, Sidekiq queues, PostgreSQL, tests with RSpec.")
)

ago = ->(hours) { now - hours.hours }
postings = [
  [ "Senior Ruby on Rails Engineer", "Lumen Pay", :remotive, "Remote · LATAM", 3, tr.("US$ 6.000–7.500/mês", "US$ 6,000–7,500/month"), "Senior Ruby on Rails engineer. PostgreSQL, Sidekiq, Redis and RSpec. Remote for Latin America, 5+ years." ],
  [ tr.("Engenheira de Software Back-end (Rails)", "Backend Software Engineer (Rails)"), "Lumi Crédito", :linkedin_alert, tr.("Remoto · Brasil", "Remote · Brazil"), 5,
    tr.("R$ 16.000–19.000", "BRL 16,000–19,000"), tr.("Ruby on Rails e PostgreSQL. Remoto para todo o Brasil. Sênior.", "Ruby on Rails and PostgreSQL. Remote anywhere in Brazil. Senior.") ],
  [ "Rails Developer", "Pomar Tech", :we_work_remotely, "Anywhere", 8, nil, "Rails and Docker. Fully remote, worldwide." ],
  [ tr.("Desenvolvedor Ruby", "Ruby Developer"), "Brisa Educação", :remotar, tr.("Remoto · Brasil", "Remote · Brazil"), 10, tr.("R$ 12.000", "BRL 12,000"),
    tr.("Ruby, GraphQL e AWS. Remoto.", "Ruby, GraphQL and AWS. Remote.") ],
  [ "Full Stack Engineer (Rails + React)", "Sabiá Mídia", :himalayas, "Remote · LATAM", 14, tr.("US$ 5.000/mês", "US$ 5,000/month"), "Ruby on Rails and React. Remote in LATAM." ],
  [ "Software Engineer II, Platform", "Atlas Cloud", :lever, "Remote · Brazil", 20, nil, "Go services, Kubernetes and AWS, some Ruby. Remote in Brazil." ],
  [ "Backend Engineer (Node.js)", "Maré Energia", :remote_ok, "Remote", 26, nil, "Node.js, TypeScript, PostgreSQL. Remote." ],
  [ "Senior Backend Engineer (Python)", "Ipê Analytics", :hacker_news, "Remote", 33, nil, "Python, Django, Postgres. Remote." ],
  [ tr.("Desenvolvedor PHP Sênior", "Senior PHP Developer"), "Rio Verde Agro", :backend_br, tr.("Remoto · Brasil", "Remote · Brazil"), 40, nil,
    tr.("PHP, Laravel, MySQL. Remoto.", "PHP, Laravel, MySQL. Remote.") ],
  [ "Staff Engineer", "Tecla", :ashby, "Remote · US only", 50, tr.("US$ 180k/ano", "US$ 180k/year"), "Ruby on Rails, PostgreSQL. Must be located in the US." ],
  [ tr.("Engenheiro de Dados", "Data Engineer"), "Faro Mobilidade", :linkedin_alert, tr.("Híbrido · Goiânia", "Hybrid · Goiânia"), 60, nil,
    tr.("Python, Spark, Airflow. Híbrido em Goiânia.", "Python, Spark, Airflow. Hybrid in Goiânia.") ]
]
created = postings.map do |title, company, source, location, hours, salary, description|
  JobIngestor.call(title:, company:, source: source.to_s, url: "https://vagas.exemplo.com/#{company.parameterize}/#{title.parameterize}",
                   location_text: location, posted_at: ago.(hours), salary_text: salary, description:).posting.tap { it.update_columns(created_at: ago.(hours)) }
end
created.find { it.company == "Faro Mobilidade" }.update!(triage: "dismissed")

fit = tr.(<<~PT.strip, <<~EN.strip)
  Fit alto (8/10). A vaga pede exatamente o seu núcleo: Rails, PostgreSQL, Sidekiq e Redis, com 5+ anos.
  Pontos fortes: filas com Sidekiq e testes com RSpec aparecem no seu perfil.
  Atenção: a vaga cita Kafka de passagem; vale dizer na conversa que você já integrou filas assíncronas.
PT
  Strong fit (8/10). The job asks for exactly your core: Rails, PostgreSQL, Sidekiq and Redis, with 5+ years.
  Strengths: Sidekiq queues and RSpec tests are in your profile.
  Watch out: the job mentions Kafka in passing; worth saying in the interview that you have integrated async queues.
EN
AiArtifact.create!(job_posting: created.first, kind: "fit_analysis", status: "completed", model: "minimax/minimax-m3.1-flash:free", content: fit)

applications = [
  [ "Ferro Digital", "Ruby Engineer", "saved", nil, nil ],
  [ "Orbitas", "Rails Developer", "saved", nil, nil ],
  [ "Vértice", "Rails Developer", "applied", 2, nil ],
  [ "Trilha Seguros", tr.("Pessoa Desenvolvedora Back-end", "Backend Developer"), "applied", 7, today ],
  [ "Ponte Fintech", "Ruby Engineer", "applied", 9, today ],
  [ "Cobalto", "Software Engineer II", "applied", 4, nil ],
  [ "Caju Bank", tr.("Engenheira de Software Back-end", "Backend Software Engineer"), "recruiter_contact", 6, today + 2 ],
  [ "Nimbus Labs", "Backend Engineer, Payments", "ai_interview", 8, nil ],
  [ "Vela Saúde", tr.("Desenvolvedor Ruby Sênior", "Senior Ruby Developer"), "hr_interview", 12, nil ],
  [ "Kora Commerce", "Full Stack Engineer", "tech_interview", 15, nil ],
  [ "Quanta Logística", "Rails Engineer", "take_home", 18, nil ],
  [ "Faro Mobilidade", "Backend Engineer", "offer", 25, nil ],
  [ "Zinco", tr.("Desenvolvedora Back-end", "Backend Developer"), "rejected", 20, nil ],
  [ "Lince", tr.("Desenvolvedor PHP", "PHP Developer"), "withdrawn", 30, nil ],
  [ "Atrio", "Ruby Developer", "no_response", 35, nil ],
  [ "Nexo Saúde", "Backend Engineer", "saved", nil, nil ],
  [ "Dobra", "Rails Engineer", "saved", nil, nil ],
  [ "Tangram", tr.("Desenvolvedora Ruby", "Ruby Developer"), "applied", 1, nil ],
  [ "Plano Alto", "Backend Developer", "applied", 3, nil ],
  [ "Granito", "Ruby on Rails Developer", "applied", 5, nil ],
  [ "Cais", "Software Engineer", "applied", 6, nil ],
  [ "Aurora Pagamentos", "Senior Rails Engineer", "recruiter_contact", 4, nil ],
  [ "Eixo", "Backend Engineer", "hr_interview", 10, nil ],
  [ "Prumo", tr.("Engenheira Back-end", "Backend Engineer"), "rejected", 16, nil ]
].map do |company, role, status, days, follow_up|
  JobApplication.create!(company:, role:, status:, origin: [ "LinkedIn", "Remotar", "Greenhouse", tr.("Indicação", "Referral"), "Gupy" ].sample(random: Random.new(company.sum)),
                         applied_on: days && today - days, next_follow_up_on: follow_up, contact_url: "https://vagas.exemplo.com/#{company.parameterize}")
end

[
  [ "Nimbus Labs", "interview", tr.("Convite para uma entrevista gravada em vídeo com IA (HireVue), com prazo de 5 dias.",
                                     "Invitation to a recorded video interview with AI (HireVue), due in 5 days."), "applied", "ai_interview", 3 ],
  [ "Vela Saúde", "interview", tr.("A recrutadora quer marcar a entrevista com o RH na quinta.", "The recruiter wants to schedule the HR interview on Thursday."), "applied", "hr_interview", 20 ],
  [ "Quanta Logística", "assessment", tr.("Desafio técnico: uma API Rails com prazo de uma semana.", "Coding challenge: a Rails API, due in a week."), "tech_interview", "take_home", 26 ],
  [ "Zinco", "rejection", tr.("Seguiram com outra pessoa nesta vaga e pedem para manter contato.", "They moved on with another candidate and would like to keep in touch."), "applied", "rejected", 30 ]
].each do |company, category, summary, before, after, hours|
  application = applications.find { it.company == company }
  ApplicationEmail.create!(job_application: application, message_id: "demo-#{company.parameterize}@exemplo.com", from_name: tr.("Recrutamento #{company}", "#{company} Recruiting"),
                           from_address: "talentos@#{company.parameterize}.exemplo.com", subject: tr.("Sua candidatura na #{company}", "Your application at #{company}"), received_at: ago.(hours),
                           category:, summary:, status_before: before, status_after: after, classified_by: "ai")
end

[
  [ "Mariana Costa", "Tech Recruiter · fintechs", "Caju Bank", "recruiter", 2 ],
  [ "Rafael Souza", "Engineering Manager", "Kora Commerce", "manager", 9 ],
  [ "Juliana Prado", "Talent Acquisition LATAM", "Nimbus Labs", "recruiter", 4 ],
  [ "Pedro Almeida", tr.("Head de Engenharia", "Head of Engineering"), "Vela Saúde", "manager", 45 ],
  [ "Camila Torres", tr.("Recrutadora tech", "Tech recruiter"), "Yoctoo", "recruiter", nil ]
].each_with_index do |(name, headline, company, kind, days), index|
  Contact.create!(name:, headline:, company:, kind:, last_contacted_on: days && today - days, linkedin_url: "https://www.linkedin.com/in/exemplo-#{index}")
end

TargetCompany.where(example: true).update_all(last_fetched_at: 2.hours.ago)
TargetCompany.create!(name: "Lumen Pay", ats: "greenhouse", board_slug: "lumenpay-exemplo", active: false, discovered_at: now, discovered_from: created.first)
TargetCompany.create!(name: "Pomar Tech", ats: "ashby", board_slug: "kora-exemplo", active: false, discovered_at: now)

(JobPosting::SOURCES - %w[extension manual]).each_with_index do |source, index|
  run = SourceRun.create!(source:, status: "succeeded", fetched_count: 20 + index * 3, created_count: index % 4, created_at: (index * 7).minutes.ago, finished_at: (index * 7).minutes.ago)
  run.update!(status: "failed", error_message: tr.("HTTP 503 do servidor da fonte", "HTTP 503 from the source's server")) if source == "working_nomads"
end

Consultancy.order(:id).limit(4).each { it.update!(registered_on: today - 10) }
# The ready-made routines are copied in the language of the first visit.
I18n.with_locale(english ? :en : :"pt-BR") { Routine.current }
%w[m1 m2 m4 a1].each { Routine.toggle!(it) }
%w[s1 s2 s3 s4 s5 s6 s7 s8 s9 s10].each { Routine.toggle!(it) }

puts "Dados de demonstração prontos (#{english ? "en" : "pt-BR"}): #{JobPosting.count} vagas, #{JobApplication.count} candidaturas."
