require "rails_helper"

RSpec.describe JobPostingFilter do
  def titles(params) = described_class.new(params).ordered.map(&:title)

  it "defaults to new postings, best score first" do
    create(:job_posting, title: "Baixa", score: 20)
    create(:job_posting, title: "Alta", score: 80)
    create(:job_posting, title: "Fora", triage: "dismissed")

    filter = described_class.new

    expect(titles({})).to eq(%w[Alta Baixa])
    expect(filter[:sort]).to eq("score")
    expect(filter).not_to be_active
  end

  it "sorts by the newest publication" do
    create(:job_posting, title: "Antiga", score: 90, posted_at: 10.days.ago)
    create(:job_posting, title: "Nova", score: 10, posted_at: 1.hour.ago)
    create(:job_posting, title: "Sem data", score: 50, posted_at: nil, created_at: 2.days.ago)

    expect(titles(sort: "recent")).to eq([ "Nova", "Sem data", "Antiga" ])
  end

  it "filters by period, keyword, salary and open region" do
    create(:job_posting, title: "Rails BR", posted_at: 2.days.ago, remote_scope: "brazil", salary_text: "R$ 10 mil",
                         matched_keywords: [ { "term" => "rails", "points" => 30 } ])
    create(:job_posting, title: "React EUA", posted_at: 2.days.ago, remote_scope: "us_only",
                         matched_keywords: [ { "term" => "react", "points" => 10 } ])
    create(:job_posting, title: "Rails velha", posted_at: 20.days.ago, remote_scope: "latam",
                         matched_keywords: [ { "term" => "rails", "points" => 30 } ])

    expect(titles(period: "7")).to contain_exactly("Rails BR", "React EUA")
    expect(titles(keyword: "rails")).to contain_exactly("Rails BR", "Rails velha")
    expect(titles(salary: "1")).to eq([ "Rails BR" ])
    expect(titles(remote_scope: "open")).to contain_exactly("Rails BR", "Rails velha")
    expect(titles(remote_scope: "us_only")).to eq([ "React EUA" ])
  end

  it "ignores unknown values and is active when something is set" do
    create(:job_posting, title: "Qualquer")

    expect(titles(sort: "evil", keyword: "cobol", period: "999", source: "x", seniority: "x", remote_scope: "x", triage: "x")).to eq([ "Qualquer" ])
    expect(described_class.new(min_score: "40")).to be_active
    expect(described_class.new(triage: "all")).to be_active
    expect(described_class.new(triage: "all").scope.count).to eq(1)
    expect(described_class.new(min_score: "40", q: "").to_params).to eq("min_score" => "40", "triage" => "new", "sort" => "score")
  end
end
