require "rails_helper"

RSpec.describe ProfileSuggestions do
  before do
    Profile.current.update!(skills: [ { "name" => "Ruby on Rails", "level" => "essential" }, { "name" => "React", "level" => "important" },
                                      { "name" => "Hotwire", "level" => "extra" } ], avoid_terms: [])
  end

  def postings(count, triage:, title: "Developer", description: "", **attributes)
    create_list(:job_posting, count, triage:, title:, description:, **attributes)
  end

  def by_kind(suggestions)
    suggestions.to_h { [ [ it.kind, it.term ], it ] }
  end

  it "says nothing before a few triages" do
    postings(5, triage: "saved", description: "Ruby on Rails and Hotwire")
    postings(10, triage: "dismissed", description: "PHP and Laravel")

    expect(described_class.new.call).to eq([])
  end

  it "suggests avoiding what you always dismiss, raising what you save and lowering what you never save" do
    postings(10, triage: "saved", description: "Ruby on Rails and Hotwire")
    postings(30, triage: "dismissed", description: "PHP and Laravel")
    postings(20, triage: "dismissed", description: "React front end")
    postings(15, triage: "dismissed", description: "Kotlin", auto_dismissed_reason: "só Europa") # not your choice

    suggestions = by_kind(described_class.new.call)

    expect(suggestions[%w[avoid PHP]]).to have_attributes(count: 30, saved: 0)
    expect(suggestions[%w[promote Hotwire]]).to have_attributes(level: "important", saved: 10, share: 100, average: 17)
    expect(suggestions[%w[demote React]]).to have_attributes(level: "extra", saved: 0, count: 20)
    expect(suggestions.keys).not_to include(%w[avoid Kotlin], %w[promote Ruby\ on\ Rails])
    expect(suggestions.size).to eq(described_class::LIMIT)
  end

  it "raises a skill whose applications get answers much more often" do
    postings(25, triage: "dismissed", description: "Java")
    hotwire = postings(4, triage: "saved", description: "Ruby on Rails and Hotwire")
    others = postings(4, triage: "saved", description: "Ruby on Rails")
    hotwire.each { create(:job_application, job_posting: it, status: "hr_interview", applied_on: 9.days.ago, responded_on: 2.days.ago) }
    others.each { create(:job_application, job_posting: it, status: "applied", applied_on: 9.days.ago) }

    promotion = by_kind(described_class.new.call)[%w[promote Hotwire]]

    expect(promotion).to have_attributes(level: "important", ratio: 2.0)
  end

  it "applies a suggestion to the profile and hides the dismissed ones" do
    postings(10, triage: "saved", description: "Ruby on Rails and Hotwire")
    postings(30, triage: "dismissed", description: "PHP")
    suggestions = described_class.new.call
    avoid = suggestions.find { it.kind == "avoid" }

    Setting.current.update!(dismissed_suggestions: [ avoid.key ])
    expect(described_class.current.map(&:key)).not_to include(avoid.key)

    described_class.new.apply(avoid)
    described_class.new.apply(suggestions.find { it.kind == "promote" })

    expect(Profile.current.avoid_terms).to eq([ "PHP" ])
    expect(Profile.current.skills.find { it["name"] == "Hotwire" }["level"]).to eq("important")
  end
end
