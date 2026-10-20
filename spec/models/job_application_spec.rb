require "rails_helper"

RSpec.describe JobApplication do
  it "appends new cards to the end of the status column" do
    first = create(:job_application, status: "applied")
    second = create(:job_application, status: "applied")
    other = create(:job_application, status: "saved")

    expect([ first.position, second.position, other.position ]).to eq([ 0, 1, 0 ])
  end

  it "fills applied_on when the status becomes applied" do
    application = create(:job_application)

    travel_to Date.new(2026, 10, 20) do
      application.update!(status: "applied")
    end

    expect(application.applied_on).to eq(Date.new(2026, 10, 20))
  end

  it "builds an application from a posting" do
    posting = create(:job_posting, title: "Rails Engineer", company: "Acme", source: "greenhouse")

    application = described_class.build_from_posting(posting)

    expect(application).to have_attributes(company: "Acme", role: "Rails Engineer", origin: "Greenhouse", job_posting: posting)
    expect(application.url).to eq(posting.url)
  end

  describe "#move_to!" do
    it "moves the card to another column at the given index" do
      a = create(:job_application, status: "applied")
      b = create(:job_application, status: "applied")
      card = create(:job_application, status: "saved")

      card.move_to!("applied", 1)

      expect(described_class.status_applied.ordered).to eq([ a, card, b ])
    end

    it "reorders inside the same column" do
      a = create(:job_application)
      b = create(:job_application)
      c = create(:job_application)

      c.move_to!("saved", 0)

      expect(described_class.status_saved.ordered).to eq([ c, a, b ])
    end
  end

  describe "scopes" do
    it "lists follow-ups due only for open applications" do
      due = create(:job_application, status: "applied", next_follow_up_on: Date.current)
      create(:job_application, status: "rejected", next_follow_up_on: Date.current)
      create(:job_application, status: "applied", next_follow_up_on: Date.tomorrow)

      expect(described_class.follow_up_due).to eq([ due ])
    end

    it "finds applications waiting for an answer for more than 5 days" do
      old = create(:job_application, status: "applied", applied_on: 6.days.ago.to_date)
      create(:job_application, status: "applied", applied_on: 2.days.ago.to_date)
      create(:job_application, status: "applied", applied_on: 9.days.ago.to_date, next_follow_up_on: Date.current)

      expect(described_class.waiting_answer).to eq([ old ])
    end
  end
end
