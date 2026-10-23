require "rails_helper"

RSpec.describe "ATS board sources" do
  describe Sources::Greenhouse do
    it "fetches each active company and keeps engineering roles" do
      company = create(:target_company, name: "GitLab", ats: "greenhouse", board_slug: "gitlab")
      create(:target_company, ats: "greenhouse", board_slug: "inactive", active: false)
      stub_source("https://boards-api.greenhouse.io/v1/boards/gitlab/jobs?content=true", "greenhouse.json")

      postings = described_class.new.fetch

      expect(postings.map { it[:title] }).to all(match(/Engineer/))
      expect(postings.size).to eq(2)
      expect(postings.first).to include(company: "GitLab", source: "greenhouse", location_text: "Remote, United Kingdom")
      expect(postings.first[:description]).to include("GitLab")
      expect(postings.first[:description]).not_to include("&lt;", "<p>")
      expect(company.reload.last_fetched_at).to be_present
    end

    it "records a warning and goes on when a board fails" do
      create(:target_company, name: "Quebrada", ats: "greenhouse", board_slug: "broken")
      stub_request(:get, %r{boards/broken}).to_return(status: 404)

      source = described_class.new

      expect(source.fetch).to eq([])
      expect(source.warnings.first).to include("Quebrada", "404")
    end
  end

  describe Sources::Lever do
    it "maps Lever postings" do
      create(:target_company, name: "Pipedrive", ats: "lever", board_slug: "pipedrive")
      stub_source("https://api.lever.co/v0/postings/pipedrive?mode=json", "lever.json")

      postings = described_class.new.fetch

      expect(postings.size).to eq(2)
      expect(postings.first).to include(company: "Pipedrive", source: "lever")
      expect(postings.first[:location_text]).to eq("Portugal, Lisbon · hybrid")
      expect(postings.first[:url]).to start_with("https://jobs.lever.co/pipedrive/")
      expect(postings.first[:posted_at]).to be_present
    end
  end

  describe Sources::Ashby do
    it "maps Ashby postings with compensation" do
      create(:target_company, name: "Kit", ats: "ashby", board_slug: "kit")
      stub_source("https://api.ashbyhq.com/posting-api/job-board/kit?includeCompensation=true", "ashby.json")

      postings = described_class.new.fetch

      expect(postings.map { it[:title] }).to eq([ "Senior Infrastructure Engineer II" ])
      expect(postings.first).to include(company: "Kit", location_text: "Remote · United States")
      expect(postings.first[:url]).to start_with("https://jobs.ashbyhq.com/kit/")
    end
  end

  describe Sources::Workable do
    it "maps the public job widget" do
      create(:target_company, name: "Zipdev", ats: "workable", board_slug: "zipdev")
      stub_source("https://apply.workable.com/api/v1/widget/accounts/zipdev?details=true", "workable.json")

      postings = described_class.new.fetch

      expect(postings.map { it[:title] }).to eq([ "QA Engineer (Automation and AI tooling)" ])
      expect(postings.first).to include(company: "Zipdev", source: "workable", location_text: "Remote · Colombia")
      expect(postings.first[:url]).to start_with("https://apply.workable.com/j/")
    end
  end

  it "registers every source" do
    expect(Sources.all.map(&:key)).to eq(%w[remotive remote_ok we_work_remotely working_nomads himalayas remotar gupy programathor vagas_com
                                            telegram backend_br frontend_br hacker_news gorails greenhouse lever ashby workable])
    expect(Sources.find("lever")).to eq(Sources::Lever)
    expect { Sources::Base.new.fetch }.to raise_error(NotImplementedError)
  end
end
