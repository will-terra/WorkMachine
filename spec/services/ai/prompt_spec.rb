require "rails_helper"

RSpec.describe Ai::Prompt do
  let(:posting) { build(:job_posting, title: "Rails Engineer", company: "Acme", location_text: "Remote - LATAM", description: "Rails 8 and Hotwire") }

  it "puts the rules and the profile in the system prompt" do
    expect(described_class.system_text).to include("Never invent", "<profile>", "Empresa A", "cadastro social", "about 3 years")
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
