require "rails_helper"

RSpec.describe JobPosting do
  it "normalizes the URL and computes the fingerprint" do
    posting = create(:job_posting, url: "https://jobs.example.com/1/?utm_source=x", company: " Acme  Inc ", title: "Ruby  Developer")

    expect(posting.url).to eq("https://jobs.example.com/1")
    expect(posting.company).to eq("Acme Inc")
    expect(posting.fingerprint).to eq("acme inc|ruby developer")
  end

  it "transliterates accents in the fingerprint" do
    expect(described_class.fingerprint_for("Gestão Pública", "Desenvolvedor Sênior")).to eq("gestao publica|desenvolvedor senior")
  end

  it "rejects a duplicated URL" do
    create(:job_posting, url: "https://jobs.example.com/1")

    expect(build(:job_posting, url: "https://jobs.example.com/1?utm_campaign=y")).not_to be_valid
  end

  it "rejects unknown enum values" do
    expect(build(:job_posting, source: "monster")).not_to be_valid
  end

  describe ".find_duplicate" do
    let!(:posting) { create(:job_posting, url: "https://jobs.example.com/1", company: "Acme", title: "Rails Engineer") }

    it "matches by URL" do
      expect(described_class.find_duplicate(url: "https://jobs.example.com/1/", company: nil, title: "x")).to eq(posting)
    end

    it "matches by company and title" do
      expect(described_class.find_duplicate(url: "https://other.com/9", company: "ACME", title: "Rails  engineer")).to eq(posting)
    end

    it "does not match by title alone" do
      expect(described_class.find_duplicate(url: "https://other.com/9", company: nil, title: "Rails Engineer")).to be_nil
    end
  end

  it "has Portuguese labels for enums" do
    posting = build(:job_posting, remote_scope: "us_only")

    expect(posting.human_enum(:remote_scope)).to eq("Só EUA")
    expect(described_class.human_enum(:source, nil)).to eq("")
    expect(posting.display_company).to eq("Acme")
    expect(build(:job_posting, company: nil).display_company).to eq("Empresa não informada")
  end
end
