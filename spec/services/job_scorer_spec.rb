require "rails_helper"

RSpec.describe JobScorer do
  def score(**args) = described_class.call(**args)

  it "adds the keyword points and explains them" do
    result = score(title: "Ruby on Rails Developer", description: "Rails 8, Hotwire, Sidekiq, PostgreSQL, React and TypeScript. Docker.", location_text: "Remote - LATAM")

    expect(result.matched_keywords.map { it["term"] }).to eq([ "rails", "ruby", "react", "hotwire/turbo/stimulus", "sidekiq", "postgres", "typescript", "docker/kubernetes", "região aberta" ])
    expect(result.score).to eq(30 + 10 + 10 + 8 + 5 + 5 + 4 + 3 + 15)
    expect(result.remote_scope).to eq("latam")
  end

  it "caps the score at 100 and never goes below 0" do
    expect(score(title: "Rails", description: "ruby react hotwire sidekiq postgres typescript docker govtech worldwide").score).to eq(95)
    expect(score(title: "Staff Python Engineer", description: "US citizens only, 10+ years").score).to eq(0)
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

  it "penalizes long experience and staff/principal titles" do
    result = score(title: "Principal Rails Engineer", description: "8+ years of Ruby")

    expect(result.matched_keywords).to include({ "term" => "7+ anos", "points" => -15 }, { "term" => "staff/principal", "points" => -10 })
    expect(score(title: "Rails Engineer", description: "3+ years").matched_keywords.map { it["term"] }).not_to include("7+ anos")
  end

  it "penalizes Europe-only and management roles" do
    terms = score(title: "Engineering Manager", description: "Rails", location_text: "Remote, Germany").matched_keywords.map { it["term"] }

    expect(terms).to include("só Europa", "gestão")
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
    expect(score(title: "Dev", description: "Sistemas para gestão pública").matched_keywords.map { it["term"] }).to eq([ "govtech" ])
  end
end
