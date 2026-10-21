require "rails_helper"

RSpec.describe Profile do
  let(:profile) { described_class.current }

  it "is the single profile of the installation, or an empty one" do
    expect(profile).to be_persisted
    described_class.delete_all
    Current.profile = nil

    expect(described_class.current).to be_new_record
    expect(described_class.current).not_to be_configured
  end

  it "cleans lists typed one per line or separated by commas" do
    profile.target_titles = "Dev Rails\n Dev Rails ; Full Stack,  "

    expect(profile.target_titles).to eq([ "Dev Rails", "Full Stack" ])
  end

  it "cleans the skills from the form" do
    profile.skills = { "0" => { "name" => " Go ", "level" => "weird", "synonyms" => "Golang, go" },
                       "1" => { "name" => "", "level" => "extra" },
                       "2" => { "name" => "Java", "level" => "extra", "_destroy" => "1" } }

    expect(profile.skills).to eq([ { "name" => "Go", "level" => "important", "synonyms" => [ "Golang" ] } ])
  end

  it "builds term regexes that work around symbols and spaces" do
    regex = described_class.terms_regex([ "C#", ".NET", "Node.js", "full stack" ])
    text = described_class.normalize_text("Full  Stack com C#, .NET e Node.js")

    expect(text.scan(regex)).to eq([ "full  stack", "c#", ".net", "node.js" ])
    expect(described_class.terms_regex([ " " ])).to be_nil
  end

  it "tells what the aggregator should keep" do
    expect(profile.relevant?("Senior Ruby Engineer")).to be(true)
    expect(profile.relevant?("Senior Go Engineer")).to be(false)

    profile.search_terms = []
    expect(profile.effective_search_terms).to eq([ "Rails", "Ruby on Rails" ])
  end

  it "asks for two plan B terms" do
    expect(profile.plan_b_relevant?("React and TypeScript")).to be(true)
    expect(profile.plan_b_relevant?("React only")).to be(false)
    expect(build(:profile, plan_b_terms: []).plan_b_relevant?("React")).to be(false)
    expect(build(:profile, plan_b_terms: [ "Flutter" ]).plan_b_relevant?("Flutter")).to be(true)
  end

  it "uses the words of its areas for company boards" do
    expect(profile.board_title_regex).to match("senior software engineer")
    expect(build(:profile, primary_area: "data", plan_b_area: nil).board_title_regex).to match("data analyst")
  end

  it "validates its values" do
    invalid = build(:profile, seniority: "guru", years_experience: -1, primary_area: "cooking", regions: %w[mars], time_zone: "Nowhere",
                              dream_posting_ids: (1..6).to_a)

    expect(invalid).not_to be_valid
    expect(invalid.errors.attribute_names).to include(:seniority, :years_experience, :primary_area, :regions, :time_zone, :dream_posting_ids)
  end

  it "rescores the postings when what scores changes" do
    expect { profile.update!(name: "Outra") }.not_to have_enqueued_job(RescorePostingsJob)
    expect { profile.update!(skills: [ { "name" => "Go", "level" => "essential" } ]) }.to have_enqueued_job(RescorePostingsJob)
  end

  it "rescores every posting with the job" do
    posting = create(:job_posting, title: "Go Developer", description: "Go", score: 0)
    profile.update!(skills: [ { "name" => "Go", "level" => "essential" } ])

    RescorePostingsJob.perform_now

    expect(posting.reload.score).to eq(30)
  end
end
