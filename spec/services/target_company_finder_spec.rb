require "rails_helper"

RSpec.describe TargetCompanyFinder do
  before do
    allow_any_instance_of(described_class).to receive(:sleep)
    stub_request(:get, /boards-api\.greenhouse\.io|api\.lever\.co|api\.ashbyhq\.com|apply\.workable\.com/).to_return(status: 404, body: "{}")
  end

  def stub_board(url, body)
    stub_request(:get, url).to_return(body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "adds the boards found by the company name, confirming the name where the ATS returns it" do
    stub_board("https://boards-api.greenhouse.io/v1/boards/fcamara", { name: "FCamara" })
    stub_board("https://api.lever.co/v0/postings/sierrastudio?mode=json&limit=1", [])
    stub_board("https://apply.workable.com/api/v1/widget/accounts/acme", { name: "Another Acme", jobs: [] })
    fcamara = create(:job_application, company: "Grupo FCamara", status: "applied")
    sierra = create(:job_application, company: "Sierra Studio", status: "tech_interview")
    acme = create(:job_application, company: "Acme", status: "applied")

    added = described_class.call

    expect(added.map { [ it.name, it.ats, it.board_slug, it.active? ] }).to contain_exactly(
      [ "FCamara", "greenhouse", "fcamara", true ], [ "Sierra Studio", "lever", "sierrastudio", true ]
    )
    expect([ fcamara, sierra, acme ].map { it.reload.board_checked_at }).to all(be_present)
    expect(described_class.new.send(:same_company?, "Encora Digital", "Encora")).to be(true)
  end

  it "uses the board links of the application's posting" do
    posting = create(:job_posting, url: "https://jobs.ashbyhq.com/kit-co/123", company: "Kit")
    application = create(:job_application, company: "Kit", status: "applied", job_posting: posting)

    expect(described_class.call.sole).to have_attributes(ats: "ashby", board_slug: "kit-co", discovered_from: posting)
    expect(application.reload.board_checked_at).to be_present
  end

  it "skips saved applications, checked ones and companies already followed" do
    create(:target_company, name: "GitLab", ats: "greenhouse", board_slug: "gitlab")
    create(:job_application, company: "GitLab", status: "applied")
    create(:job_application, company: "Saved Co", status: "saved")
    create(:job_application, company: "Checked Co", status: "applied", board_checked_at: 1.day.ago)

    expect(described_class.call).to be_empty
    expect(WebMock).not_to have_requested(:get, /saved|checked/)
    expect(WebMock).not_to have_requested(:get, %r{boards/gitlab})
  end

  it "runs when you apply and fetches the new boards" do
    application = create(:job_application, company: "Acme", status: "saved")

    expect { application.update!(status: "applied") }.to have_enqueued_job(FindTargetCompaniesJob)

    allow(described_class).to receive(:call).and_return([ build(:target_company, ats: "lever") ])
    expect { FindTargetCompaniesJob.perform_now }.to have_enqueued_job(FetchJobsJob).with(%w[lever], force: true)
  end
end
