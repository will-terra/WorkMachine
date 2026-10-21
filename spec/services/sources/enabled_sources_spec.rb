require "rails_helper"

RSpec.describe "Sources for the profile" do
  let(:profile) { Profile.current }

  it "runs the niche sources only when they match the profile" do
    expect(Sources.enabled.map(&:key)).to include("gorails", "backend_br", "frontend_br", "hacker_news")

    data = build(:profile, primary_area: "data", plan_b_area: nil, skills: [ { "name" => "Python", "level" => "essential" } ], search_terms: [])
    keys = Sources.enabled(data).map(&:key)
    expect(keys).to include("remotive", "hacker_news", "greenhouse")
    expect(keys).not_to include("gorails", "backend_br", "frontend_br")
  end

  it "leaves out the sources turned off in Ajustes, keeping the others' state" do
    setting = Setting.current
    setting.update!(enabled_sources: Sources.all.map(&:key) - %w[remote_ok])
    expect(Sources.enabled.map(&:key)).not_to include("remote_ok")

    Current.profile = build(:profile, primary_area: "design", plan_b_area: nil, skills: [ { "name" => "Figma", "level" => "essential" } ], search_terms: [])
    setting.update!(enabled_sources: [])
    expect(setting.disabled_sources).to include("remote_ok", "remotive")
    expect(setting.disabled_sources).not_to include("gorails", "backend_br")
  end

  it "reads the We Work Remotely feeds of the profile's area" do
    expect(Sources::WeWorkRemotely.feeds(profile)).to eq(%w[
      https://weworkremotely.com/categories/remote-full-stack-programming-jobs.rss
      https://weworkremotely.com/categories/remote-back-end-programming-jobs.rss
    ])
    expect(Sources::WeWorkRemotely.feeds(build(:profile, primary_area: "design"))).to eq([ "https://weworkremotely.com/categories/remote-design-jobs.rss" ])
    expect(Sources::WeWorkRemotely.feeds(Profile.new)).to eq(Sources::WeWorkRemotely.feeds(profile))
  end

  it "searches with the profile's terms, at most two" do
    profile.update!(search_terms: [ "elixir", "phoenix", "erlang" ])
    stub_request(:get, "https://remotive.com/api/remote-jobs?search=elixir").to_return(body: { jobs: [] }.to_json)
    stub_request(:get, "https://remotive.com/api/remote-jobs?search=phoenix").to_return(body: { jobs: [] }.to_json)

    expect(Sources::Remotive.new(profile).fetch).to eq([])
  end

  it "keeps plan B jobs in frontendbr" do
    stub_all_sources

    titles = Sources::FrontendBr.new.fetch.map { it[:title] }
    expect(titles).not_to be_empty
    expect(Sources::FrontendBr.new(build(:profile, plan_b_terms: [], search_terms: [ "cobol" ])).fetch).to eq([])
  end

  it "does not fetch anything before the profile is filled in" do
    Profile.delete_all
    Current.profile = nil

    expect { FetchJobsJob.perform_now(force: true) }.not_to change(SourceRun, :count)
  end
end
