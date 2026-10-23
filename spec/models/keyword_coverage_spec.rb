require "rails_helper"

RSpec.describe KeywordCoverage do
  before { Profile.current.update!(skills: [ { "name" => "Ruby on Rails", "level" => "essential", "synonyms" => [ "Rails" ] } ]) }

  it "counts the job's technologies that the CV mentions, synonyms included" do
    posting = build(:job_posting, title: "Rails Engineer", description: "Rails, PostgreSQL, Redis and Kubernetes.")

    result = described_class.call(posting, "Ruby on Rails developer. PostgreSQL and Redis in production.")

    expect(result.covered).to contain_exactly("Ruby on Rails", "PostgreSQL", "Redis")
    expect(result.missing).to eq([ "Kubernetes" ])
    expect(result.total).to eq(4)
  end

  it "does not count an area's term again when a skill of the profile is part of it" do
    Profile.current.update!(skills: [ { "name" => "Rails", "level" => "essential" }, { "name" => "Ruby", "level" => "essential" } ])

    result = described_class.call(build(:job_posting, title: "Ruby on Rails Engineer", description: ""), "Ruby on Rails")

    expect(result.covered).to contain_exactly("Rails", "Ruby")
  end

  it "has nothing to count when the job names no known technology" do
    expect(described_class.call(build(:job_posting, title: "Analyst", description: "Spreadsheets."), "CV").total).to eq(0)
  end
end
