FactoryBot.define do
  # A full-stack Rails + React profile, the one the scorer and source specs are written against.
  factory :profile do
    name { "Ana Souza" }
    headline { "Full Stack Engineer (Ruby on Rails + React)" }
    primary_area { "fullstack" }
    plan_b_area { "frontend" }
    target_titles { [ "Desenvolvedora Ruby on Rails" ] }
    target_titles_en { [ "Ruby on Rails Developer", "Full Stack Engineer" ] }
    seniority { "mid" }
    years_experience { 3 }
    skills do
      [
        { "name" => "Rails", "level" => "essential", "synonyms" => [ "Ruby on Rails" ] },
        { "name" => "Ruby", "level" => "important" },
        { "name" => "React", "level" => "important", "synonyms" => [ "React.js", "ReactJS" ] },
        { "name" => "Hotwire", "level" => "important", "synonyms" => [ "Turbo", "Stimulus" ] },
        { "name" => "Sidekiq", "level" => "extra" },
        { "name" => "Postgres", "level" => "extra", "synonyms" => [ "PostgreSQL" ] },
        { "name" => "TypeScript", "level" => "extra" },
        { "name" => "Docker", "level" => "extra", "synonyms" => [ "Kubernetes", "K8s" ] },
        { "name" => "GovTech", "level" => "extra", "synonyms" => [ "public sector", "setor público", "gestão pública" ] }
      ]
    end
    search_terms { %w[rails ruby] }
    plan_b_terms { [ "React", "TypeScript", "Next.js" ] }
    domains { [ "GovTech", "setor público" ] }
    ai_profile { "# Ana Souza\n\nFull stack engineer with 3 years of Ruby on Rails and React." }
  end
end
