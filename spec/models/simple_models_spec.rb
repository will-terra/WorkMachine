require "rails_helper"

RSpec.describe "Supporting models" do
  describe TargetCompany do
    it "builds the public board URL" do
      expect(build(:target_company, ats: "lever", board_slug: " Acme ").tap(&:validate).board_url).to eq("https://jobs.lever.co/acme")
    end

    it "validates the slug format" do
      expect(build(:target_company, board_slug: "acme/../x")).not_to be_valid
    end
  end

  describe Consultancy do
    it "knows when it is registered" do
      expect(build(:consultancy, registered_on: Date.current)).to be_registered
      expect(build(:consultancy)).not_to be_registered
    end
  end

  describe Contact do
    it "stores a blank LinkedIn URL as nil" do
      expect(create(:contact, linkedin_url: " ").linkedin_url).to be_nil
    end

    it "stores the canonical LinkedIn profile URL" do
      expect(build(:contact, linkedin_url: "https://br.linkedin.com/in/Mariana-S/?trk=x").linkedin_url).to eq("https://www.linkedin.com/in/mariana-s")
      expect(build(:contact, linkedin_url: "https://example.com/mariana").linkedin_url).to eq("https://example.com/mariana")
    end
  end

  describe MessageTemplate do
    it "fills the placeholders and keeps the blank ones" do
      template = build(:message_template, body: "Oi, {{nome}}! Vaga de {{ cargo }} na {{empresa}}.")

      expect(template.render(nome: "Ana", cargo: "Rails Dev", empresa: "")).to eq("Oi, Ana! Vaga de Rails Dev na {{empresa}}.")
    end
  end

  describe AiArtifact do
    it "orders the latest first" do
      older = create(:ai_artifact, created_at: 2.days.ago)
      newer = create(:ai_artifact)

      expect(described_class.latest_first).to eq([ newer, older ])
    end
  end
end
