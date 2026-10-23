require "rails_helper"

RSpec.describe ClosedPostings do
  def board_posting(id, board: "gitlab", **attributes)
    create(:job_posting, source: "greenhouse", external_id: id.to_s, raw: { "id" => id, "board" => board },
                         url: "https://job-boards.greenhouse.io/#{board}/jobs/#{id}", **attributes)
  end

  it "finds the ATS, the board and the job from the source or from the link" do
    expect(described_class.ref(board_posting(11))).to eq([ "greenhouse", "gitlab", "11" ])
    expect(described_class.ref(build(:job_posting, source: "extension", url: "https://jobs.lever.co/Pipedrive/0b3c7e1e-1111-2222-3333-444455556666")))
      .to eq([ "lever", "pipedrive", "0b3c7e1e-1111-2222-3333-444455556666" ])
    expect(described_class.ref(build(:job_posting, source: "linkedin_alert", url: "https://jobs.ashbyhq.com/kit/0b3c7e1e-1111-2222-3333-444455556666?src=li")))
      .to eq([ "ashby", "kit", "0b3c7e1e-1111-2222-3333-444455556666" ])
    expect(described_class.ref(build(:job_posting, source: "manual", url: "https://apply.workable.com/acme/j/AB12CD34/"))).to eq([ "workable", "acme", "AB12CD34" ])
    expect(described_class.ref(build(:job_posting, source: "remotive", url: "https://remotive.com/jobs/1"))).to be_nil
  end

  it "closes the jobs that left the board, takes the new ones out of the triage and reopens the ones that come back" do
    still_open = board_posting(1)
    new_closed = board_posting(2)
    saved_closed = board_posting(3, triage: "saved")
    by_hand = create(:job_posting, source: "extension", url: "https://boards.greenhouse.io/gitlab/jobs/4")
    other_board = board_posting(5, board: "gusto")

    travel_to(Time.zone.local(2026, 10, 22, 12)) { described_class.mark("greenhouse", "GitLab", [ 1 ]) }

    expect(still_open.reload.closed_at).to be_nil
    expect(new_closed.reload).to have_attributes(closed_at: Time.zone.local(2026, 10, 22, 12), triage: "dismissed", auto_dismissed_reason: "vaga encerrada")
    expect(saved_closed.reload).to have_attributes(triage: "saved", closed_at: be_present)
    expect(by_hand.reload).to have_attributes(triage: "new", closed_at: be_present)
    expect(other_board.reload.closed_at).to be_nil
    expect(JobScorer.human_term("vaga encerrada")).to eq("vaga encerrada")

    described_class.mark("greenhouse", "gitlab", [ 1, 2 ])
    expect(new_closed.reload).to have_attributes(closed_at: nil, triage: "new", auto_dismissed_reason: nil)
  end

  it "checks the boards of tracked jobs that the aggregator did not just read" do
    create(:target_company, ats: "greenhouse", board_slug: "gitlab", last_fetched_at: 1.hour.ago)
    board_posting(1) # its board was just read
    lever = create(:job_posting, source: "extension", triage: "saved", url: "https://jobs.lever.co/pipedrive/0b3c7e1e-1111-2222-3333-444455556666")
    gone = create(:job_posting, source: "extension", triage: "saved", url: "https://apply.workable.com/gone/j/AB12CD34")
    create(:job_posting, source: "extension", triage: "dismissed", url: "https://jobs.ashbyhq.com/kit/0b3c7e1e-1111-2222-3333-444455556666")
    stub_request(:get, "https://api.lever.co/v0/postings/pipedrive?mode=json").to_return(body: [ { id: "other" } ].to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://apply.workable.com/api/v1/widget/accounts/gone").to_return(status: 404)

    CheckClosedPostingsJob.perform_now

    expect(lever.reload.closed_at).to be_present
    expect(gone.reload.closed_at).to be_present
    expect(WebMock).not_to have_requested(:get, /greenhouse|ashbyhq/)
  end

  it "keeps the jobs open when a board cannot be read" do
    posting = create(:job_posting, source: "extension", triage: "saved", url: "https://jobs.lever.co/pipedrive/0b3c7e1e-1111-2222-3333-444455556666")
    stub_request(:get, %r{api.lever.co}).to_return(status: 500)

    described_class.check

    expect(posting.reload.closed_at).to be_nil
  end
end
