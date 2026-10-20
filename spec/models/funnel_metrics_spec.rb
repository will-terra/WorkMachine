require "rails_helper"

RSpec.describe FunnelMetrics do
  let(:today) { Date.new(2026, 10, 21) }

  def metrics(period: "90") = described_class.new(period:, today:)

  before do
    create(:job_application, origin: "Remotar", status: "applied", applied_on: today - 2)
    create(:job_application, origin: "Remotar", status: "rejected", applied_on: today - 10, responded_on: today - 4)
    create(:job_application, origin: "Remotar", status: "tech_interview", applied_on: today - 9, responded_on: today - 7)
    offer = create(:job_application, origin: "Alerta do LinkedIn", status: "offer", applied_on: today - 20, responded_on: today - 10)
    create(:application_email, job_application: offer, category: "offer")
    create(:job_application, origin: nil, status: "applied", applied_on: today - 200)
    create(:job_application, status: "saved", applied_on: nil)
  end

  it "computes the funnel and the rates of the period" do
    m = metrics

    expect([ m.applied, m.answered, m.interviewed, m.offers ]).to eq([ 4, 3, 2, 1 ])
    expect(m.funnel.map { [ it.label, it.count, it.rate ] }).to eq([ [ "Aplicadas", 4, 100 ], [ "Responderam", 3, 75 ], [ "Entrevista ou teste", 2, 50 ], [ "Proposta", 1, 25 ] ])
    expect(m.response_rate).to eq(75)
    expect(m.median_days_to_answer).to eq(6)
  end

  it "counts an interview e-mail even after a rejection" do
    rejected = JobApplication.find_by!(status: "rejected")
    create(:application_email, job_application: rejected, category: "interview")

    expect(metrics.interviewed).to eq(3)
  end

  it "groups by origin and lists the weeks of the period" do
    m = metrics(period: "30")

    expect(m.by_origin.map { [ it.name, it.total, it.response_rate, it.interview_rate ] }).to eq([ [ "Remotar", 3, 67, 33 ], [ "Alerta do LinkedIn", 1, 100, 100 ] ])
    expect(m.weekly.size).to eq(5)
    expect(m.weekly.last).to eq([ today.beginning_of_week, 1 ])
    expect(m.weekly.sum(&:last)).to eq(4)
  end

  it "covers everything with Tudo, up to 26 weeks, and an even median" do
    m = metrics(period: "all")

    expect(m.applied).to eq(5)
    expect(m.by_origin.map(&:name)).to include("Sem origem")
    expect(m.weekly.size).to eq(26)
    expect(m.median_days_to_answer).to eq(6)

    create(:job_application, status: "hr_interview", applied_on: today - 5, responded_on: today - 1)
    expect(metrics(period: "all").median_days_to_answer).to eq(5)
  end

  it "ranks the posting sources by how many postings were saved" do
    create_list(:job_posting, 2, source: "remotar", triage: "saved")
    create(:job_posting, source: "remotar")
    create_list(:job_posting, 3, source: "greenhouse")
    create(:job_posting, source: "greenhouse", triage: "saved", created_at: today - 100)

    sources = metrics.by_source

    expect(sources.map { [ it.source, it.total, it.saved, it.saved_rate ] }).to eq([ [ "remotar", 3, 2, 67 ], [ "greenhouse", 3, 0, 0 ] ])
  end

  it "falls back to 90 days for an unknown period and handles no data" do
    expect(metrics(period: "x").period).to eq("90")
    JobApplication.delete_all
    expect(metrics).to have_attributes(applied: 0, response_rate: 0, median_days_to_answer: nil)
  end
end
