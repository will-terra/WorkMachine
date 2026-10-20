require "rails_helper"

RSpec.describe TargetCompanyDiscovery do
  it "registers the boards found in a relevant posting as active companies" do
    posting = create(:job_posting, score: 60, company: "Sierra Studio", url: "https://remotar.com.br/job/1",
                                   description: "Apply at https://jobs.lever.co/acme-inc/123 or job-boards.greenhouse.io/embed/job_app?for=globex&token=1",
                                   raw: { "apply_url" => "https://jobs.ashbyhq.com/sierra-studio/30a83060/application" })

    companies = described_class.call(posting)

    expect(companies.map { [ it.ats, it.board_slug, it.active? ] }).to contain_exactly(
      [ "greenhouse", "globex", true ], [ "lever", "acme-inc", true ], [ "ashby", "sierra-studio", true ]
    )
    expect(companies.find { it.ats == "lever" }).to have_attributes(name: "Acme Inc", discovered_from: posting, discovered_at: be_present)
  end

  it "uses the posting company when the posting is on that board and suggests when the score is low" do
    posting = create(:job_posting, score: 20, company: "Zipdev", url: "https://apply.workable.com/zipdev/j/9D0E6DEBAC")

    company = described_class.call(posting).sole

    expect(company).to have_attributes(name: "Zipdev", ats: "workable", board_slug: "zipdev", active: false)
    expect(TargetCompany.suggested).to eq([ company ])
  end

  it "skips known boards and reserved paths" do
    create(:target_company, ats: "greenhouse", board_slug: "gitlab")
    posting = create(:job_posting, url: "https://job-boards.greenhouse.io/gitlab/jobs/1", description: "apply.workable.com/j/ABC and apply.workable.com/api/v1")

    expect(described_class.call(posting)).to be_empty
  end

  it "runs for every new posting saved by the ingestor" do
    JobIngestor.call(source: "extension", title: "Rails Engineer", company: "Kit", url: "https://jobs.ashbyhq.com/kit-co/abc", description: "Ruby on Rails")

    expect(TargetCompany.find_by!(ats: "ashby", board_slug: "kit-co")).to have_attributes(name: "Kit", active: true)
  end
end
