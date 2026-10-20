require "rails_helper"

RSpec.describe JobIngestor do
  let(:attributes) do
    { source: "remotive", title: "Rails Engineer", company: "Acme", url: "https://jobs.example.com/1?utm_source=x",
      description: "Ruby on Rails and React", location_text: "Worldwide" }
  end

  it "creates a scored posting" do
    result = described_class.call(attributes)

    expect(result).to be_created
    expect(result.posting).to have_attributes(score: 65, remote_scope: "worldwide", url: "https://jobs.example.com/1")
  end

  it "dedups by URL and by company + title" do
    described_class.call(attributes)

    expect(described_class.call(attributes.merge(url: "https://jobs.example.com/1"))).to be_duplicate
    expect(described_class.call(attributes.merge(url: "https://other.example.com/9", company: "ACME"))).to be_duplicate
    expect(JobPosting.count).to eq(1)
  end

  it "fills blank fields of an existing posting and rescores it" do
    first = described_class.call(attributes.merge(source: "linkedin_alert", description: nil, location_text: nil)).posting
    expect(first.score).to eq(30)

    described_class.call(attributes.merge(source: "extension"))

    expect(first.reload).to have_attributes(description: "Ruby on Rails and React", source: "linkedin_alert", score: 65)
  end

  it "uses the remote scope hint" do
    result = described_class.call(attributes.merge(location_text: "Remoto", remote_scope_hint: "brazil"))

    expect(result.posting.remote_scope).to eq("brazil")
  end

  it "reports invalid postings" do
    result = described_class.call(attributes.merge(title: ""))

    expect(result).to be_invalid
    expect(result.posting.errors[:title]).to be_present
  end

  it "treats a URL taken between the lookup and the save as a duplicate" do
    existing = create(:job_posting, url: "https://jobs.example.com/1")
    allow(JobPosting).to receive(:find_duplicate).and_return(nil)

    result = described_class.call(attributes)

    expect(result).to be_duplicate
    expect(result.posting).to eq(existing)
  end

  it "handles a race on the unique URL index" do
    existing = create(:job_posting, url: "https://jobs.example.com/1")
    allow(JobPosting).to receive(:find_duplicate).and_return(nil)
    allow_any_instance_of(JobPosting).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

    expect(described_class.call(attributes).posting).to eq(existing)
  end
end
