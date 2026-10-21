require "rails_helper"

RSpec.describe JobScorer do
  def score(**args) = described_class.call(**args)

  it "adds the points of the profile's skill levels and explains them" do
    result = score(title: "Ruby on Rails Developer", description: "Rails 8, Hotwire, Sidekiq, PostgreSQL, React and TypeScript. Docker.", location_text: "Remote - LATAM")

    expect(result.matched_keywords.map { it["term"] }).to eq([ "Rails", "Ruby", "React", "Hotwire", "Sidekiq", "Postgres", "TypeScript", "Docker", "região aberta" ])
    expect(result.score).to eq(30 + 10 + 10 + 10 + 5 + 5 + 5 + 5 + 15)
    expect(result.remote_scope).to eq("latam")
  end

  it "matches synonyms, without caring about accents or case" do
    terms = score(title: "Dev", description: "Stack: ReactJS, Turbo e Gestao Publica").matched_keywords.map { it["term"] }

    expect(terms).to eq([ "React", "Hotwire", "GovTech" ])
    expect(score(title: "Railsy", description: "Rubyist").matched_keywords).to be_empty
  end

  it "scores another profile by its own skills" do
    profile = build(:profile, skills: [ { "name" => "Python", "level" => "essential" }, { "name" => "C#", "level" => "extra" }, { "name" => ".NET", "level" => "extra" } ])
    result = score(title: "Python Developer", description: "C# and .NET are a plus. Rails too.", profile:)

    expect(result.matched_keywords.map { it["term"] }).to eq([ "Python", "C#", ".NET" ])
    expect(result.score).to eq(40)
  end

  it "caps the score at 100 and never goes below 0" do
    expect(score(title: "Rails", description: "ruby react hotwire sidekiq postgres typescript docker govtech worldwide").score).to eq(100)
    expect(score(title: "Staff Python Engineer", description: "US citizens only, 10+ years").score).to eq(0)
  end

  it "takes points away for the terms to avoid" do
    profile = build(:profile, avoid_terms: [ "PHP", "presencial" ])
    result = score(title: "Rails + PHP", description: "Trabalho presencial", profile:)

    expect(result.matched_keywords).to include({ "term" => "evitar: PHP", "points" => -15 }, { "term" => "evitar: presencial", "points" => -15 })
    expect(result.score).to eq(0)
  end

  it "does not penalize the regions the profile accepts" do
    profile = build(:profile, regions: %w[brazil latam worldwide us])

    expect(score(title: "Rails Engineer", description: "US only", profile:).score).to eq(30)
    expect(score(title: "Rails Engineer", description: "US only").score).to eq(0)
  end

  it "penalizes US-only roles" do
    result = score(title: "Rails Engineer", description: "Must be located in the US.", location_text: "Remote")

    expect(result.remote_scope).to eq("us_only")
    expect(result.matched_keywords).to include({ "term" => "só EUA/Canadá", "points" => -40 })
  end

  it "treats a North America location as US only" do
    expect(score(title: "Rails Engineer", location_text: "USA, Canada, USA timezones").remote_scope).to eq("us_only")
    expect(score(title: "Rails Engineer", location_text: "Remote, Canada").remote_scope).to eq("us_only")
    expect(score(title: "Rails Engineer", location_text: "USA or LATAM").remote_scope).to eq("latam")
    expect(score(title: "Rails Engineer", location_text: "Framingham, MA, Remote").remote_scope).to eq("us_only")
    expect(score(title: "Rails Engineer", location_text: "New York, NY - Hybrid; San Francisco, CA").remote_scope).to eq("us_only")
    expect(score(title: "Dev Rails", location_text: "Florianópolis, SC").remote_scope).to eq("brazil")
    expect(score(title: "Rails Engineer", location_text: "PrizePicks · Estados Unidos (Remoto)").remote_scope).to eq("us_only")
    expect(score(title: "Rails Engineer", location_text: "Reino Unido (Remoto)").remote_scope).to eq("europe_only")
    expect(score(title: "Rails Engineer", location_text: "Índia (Remoto)").matched_keywords.map { it["term"] }).to include("local restrito")
  end

  it "penalizes a list of countries outside Latin America" do
    result = score(title: "Backend Engineer (Ruby)", location_text: "Remote, Canada; Remote, Poland; Remote, India")

    expect(result.remote_scope).to eq("unknown")
    expect(result.matched_keywords).to include({ "term" => "local restrito", "points" => -40 })
    expect(score(title: "Rails", location_text: "Remote, Canada; Remote, Brazil").matched_keywords.map { it["term"] }).not_to include("local restrito")
  end

  it "detects Europe-only, Brazil, worldwide and unknown" do
    expect(score(title: "Rails Engineer", location_text: "Remote, United Kingdom").remote_scope).to eq("europe_only")
    expect(score(title: "Rails Engineer", description: "EU only").remote_scope).to eq("europe_only")
    expect(score(title: "Dev Rails", location_text: "Remoto · Porto Alegre").remote_scope).to eq("brazil")
    expect(score(title: "Rails Engineer", location_text: "Anywhere in the World").remote_scope).to eq("worldwide")
    expect(score(title: "Rails Engineer").remote_scope).to eq("unknown")
    expect(score(title: "Dev Rails", remote_scope_hint: "brazil").remote_scope).to eq("brazil")
  end

  it "penalizes asking for many more years than the profile has, and staff/principal titles" do
    result = score(title: "Principal Rails Engineer", description: "8+ years of Ruby")

    expect(result.matched_keywords).to include({ "term" => "8+ anos", "points" => -15 }, { "term" => "staff/principal", "points" => -10 })
    expect(result.matched_keywords.map { it["term"] }).not_to include("sênior")
    expect(score(title: "Rails Engineer", description: "4+ years").matched_keywords.map { it["term"] }).not_to include("4+ anos")
    expect(score(title: "Rails Engineer", description: "8+ years", profile: build(:profile, years_experience: 7)).matched_keywords.map { it["term"] }).not_to include("8+ anos")
    expect(score(title: "Rails Engineer", description: "8+ years", profile: build(:profile, years_experience: nil)).matched_keywords.map { it["term"] }).not_to include("8+ anos")
  end

  it "penalizes titles above the profile's level and a few extra years lightly" do
    terms = score(title: "Senior Rails Engineer", description: "5+ years with Ruby").matched_keywords

    expect(terms).to include({ "term" => "sênior", "points" => -10 }, { "term" => "5+ anos", "points" => -10 })
    expect(score(title: "Tech Lead Ruby", description: "6 anos").matched_keywords.map { it["term"] }).to include("sênior", "6+ anos")
    expect(score(title: "Senior Rails Engineer", profile: build(:profile, seniority: "senior")).matched_keywords.map { it["term"] }).not_to include("sênior")
    expect(score(title: "Desenvolvedor Rails Pleno", profile: build(:profile, seniority: "junior")).matched_keywords.map { it["term"] }).to include("pleno")
  end

  it "penalizes Europe-only and management roles, unless management is the goal" do
    terms = score(title: "Engineering Manager", description: "Rails", location_text: "Remote, Germany").matched_keywords.map { it["term"] }

    expect(terms).to include("só Europa", "gestão")
    product = build(:profile, target_titles_en: [ "Product Manager" ])
    expect(score(title: "Senior Product Manager", profile: product).matched_keywords.map { it["term"] }).not_to include("gestão")
  end

  it "detects seniority" do
    expect(score(title: "Senior Rails Engineer").seniority).to eq("senior")
    expect(score(title: "Desenvolvedor Ruby Júnior").seniority).to eq("junior")
    expect(score(title: "Desenvolvedor Ruby Pleno").seniority).to eq("mid")
    expect(score(title: "Software Engineer II").seniority).to eq("mid")
    expect(score(title: "Rails Engineer", description: "mid-level role").seniority).to eq("mid")
    expect(score(title: "Rails Engineer").seniority).to eq("unknown")
  end

  it "scores GovTech in Portuguese" do
    expect(score(title: "Dev", description: "Sistemas para gestão pública").matched_keywords.map { it["term"] }).to eq([ "GovTech" ])
  end

  it "scores nothing but the region for an empty profile" do
    expect(score(title: "Rails Engineer", location_text: "LATAM", profile: Profile.new).score).to eq(15)
  end
end
