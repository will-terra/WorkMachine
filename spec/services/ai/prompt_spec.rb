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

  it "prepares an interview with the stage, the sheet in the interface language and the company's e-mails" do
    application = create(:job_application, company: "Acme", role: "Rails Engineer", status: "ai_interview", notes: "Falar com a Bia.",
                                           job_posting: create(:job_posting, title: "Rails Engineer", company: "Acme", description: "Rails 8 and Hotwire"))
    create(:application_email, job_application: application, summary: "Entrevista gravada no HireVue, prazo de 5 dias.", category: "interview")
    create(:application_email, job_application: application, summary: "Newsletter.", category: "unrelated")

    text = described_class.user_text("interview_prep", nil, application:)

    expect(text).to include("has an asynchronous interview", "preparation sheet in Brazilian Portuguese", "Perguntas técnicas prováveis",
                            "[complete com um exemplo seu]", "Rails 8 and Hotwire", "<application_history>", "HireVue", "Falar com a Bia.")
    expect(text).not_to include("Newsletter")
    expect(I18n.with_locale(:en) { described_class.user_text("interview_prep", nil, application:) }).to include("Likely technical questions", "[complete with your own example]")
  end

  it "prepares from the application alone when it has no posting" do
    application = create(:job_application, company: "Globex", role: "Backend Developer", status: "hr_interview")

    expect(described_class.user_text("interview_prep", nil, application:)).to include("an interview with HR", "Title: Backend Developer", "Company: Globex", "prepare from the title")
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

  it "answers the fit analysis in the interface language" do
    expect(described_class.user_text("fit_analysis", posting)).to include("Answer in Brazilian Portuguese", "Aderência:")

    english = I18n.with_locale(:en) { described_class.user_text("fit_analysis", posting) }
    expect(english).to include("Answer in English", "Fit:", "Gaps:", "Worth applying?:")
    expect(english).not_to include("Aderência")
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
