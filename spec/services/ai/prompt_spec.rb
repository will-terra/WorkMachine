require "rails_helper"

RSpec.describe Ai::Prompt do
  let(:posting) { build(:job_posting, title: "Rails Engineer", company: "Acme", location_text: "Remote - LATAM", description: "Rails 8 and Hotwire") }

  it "puts the rules and the profile in the system prompt" do
    expect(described_class.system_text).to include("You help Ana Souza", "Never invent", "<profile>", "3 years of Ruby on Rails", "about 3 years")
    expect(described_class.system_text).not_to include("dream_jobs")
  end

  it "writes the profile from the form when there is no text for the AI" do
    profile = build(:profile, name: nil, ai_profile: "", years_experience: nil)

    text = described_class.system_text(profile)
    expect(text).to include("You help the candidate", "Rails (essential)")
    expect(text).not_to include("years of professional experience")
  end

  it "adds the dream jobs and the goal of the profile" do
    dream = create(:job_posting, title: "Staff Rails Engineer", company: "Dream Co", description: "Build Rails apps")
    Profile.current.update!(dream_posting_ids: [ dream.id ], salary_usd_min: 4000, salary_usd_max: 6000)

    expect(described_class.system_text).to include("<dream_jobs>", "Staff Rails Engineer at Dream Co: Build Rails apps")
    expect(described_class.task("fit_analysis", "pt")).to include("they want a mid-level, fully remote role, open to Brazil, Latin America and anywhere in the world (salary range: US$ 4000–6000)")
  end

  it "keeps the system prompt free of per-posting data so the cache is shared" do
    expect(described_class.system_text).not_to include("Acme")
  end

  it "builds each task with the posting after it" do
    fit = described_class.user_text("fit_analysis", posting)
    cv = described_class.user_text("cv_summary", posting)

    expect(fit).to include("Aderência:", "Lacunas:", "<job_posting>", "Title: Rails Engineer", "Rails 8 and Hotwire")
    expect(cv).to include("4 to 5 lines", "language the posting is written in")
  end

  it "uses the templates of the chosen language for messages" do
    create(:message_template, name: "Conexão (PT)", language: "pt", body: "Oi, {{nome}}!")
    create(:message_template, name: "Connection (EN)", language: "en", body: "Hi {{nome}}!")

    en = described_class.user_text("message", posting, language: "en")

    expect(en).to include("in English", "Hi {{nome}}!")
    expect(en).not_to include("Oi, {{nome}}!")
  end

  it "says when the posting has no description" do
    expect(described_class.posting_block(build(:job_posting, description: nil, company: nil))).to include("no description", "Company: not informed")
  end
end
