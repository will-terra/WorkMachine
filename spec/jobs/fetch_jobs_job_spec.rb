require "rails_helper"

RSpec.describe FetchJobsJob do
  before { stub_all_sources }

  it "runs every due source, saves scored postings and records the runs" do
    create(:target_company, ats: "greenhouse", board_slug: "gitlab")
    stub_source("https://boards-api.greenhouse.io/v1/boards/gitlab/jobs?content=true", "greenhouse.json")

    described_class.perform_now

    expect(SourceRun.status_succeeded.pluck(:source)).to match_array(Sources.all.map(&:key))
    expect(JobPosting.distinct.pluck(:source)).to include("remotive", "we_work_remotely", "hacker_news", "gorails", "greenhouse")
    expect(JobPosting.find_by!(title: "Tech Lead Full-Stack Rails Engineer")).to have_attributes(remote_scope: "us_only")
    expect(SourceRun.find_by!(source: "gorails")).to have_attributes(fetched_count: 4, created_count: 4)
  end

  it "does not duplicate postings on the next run" do
    described_class.perform_now(force: true)

    expect { described_class.perform_now(force: true) }.not_to change(JobPosting, :count)
  end

  it "skips sources that ran recently unless forced" do
    SourceRun.create!(source: "remotive", status: "succeeded")

    described_class.perform_now(%w[remotive])
    expect(WebMock).not_to have_requested(:get, /remotive/)

    described_class.perform_now(%w[remotive], force: true)
    expect(WebMock).to have_requested(:get, /remotive/).twice
  end

  it "records a failure without stopping the other sources" do
    stub_request(:get, "https://remoteok.com/api").to_return(status: 503)

    described_class.perform_now(%w[remote_ok gorails])

    expect(SourceRun.find_by!(source: "remote_ok")).to have_attributes(status: "failed", error_message: /503/)
    expect(SourceRun.find_by!(source: "gorails")).to be_status_succeeded
  end

  it "keeps per-company warnings on a successful run" do
    create(:target_company, name: "Quebrada", ats: "lever", board_slug: "broken")
    stub_request(:get, %r{api.lever.co/v0/postings/broken}).to_return(status: 404)

    described_class.perform_now(%w[lever])

    expect(SourceRun.find_by!(source: "lever")).to have_attributes(status: "succeeded", error_message: /Quebrada/)
  end
end
