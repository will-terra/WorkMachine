require "rails_helper"

RSpec.describe WeeklySummary do
  let(:sunday) { Date.new(2026, 10, 25) }
  let(:summary) { described_class.new(today: sunday) }

  around { |example| travel_to(sunday.in_time_zone.change(hour: 18)) { example.run } }

  it "counts the week's applications, replies and interview invitations" do
    create_list(:job_application, 2, status: "applied", applied_on: sunday - 2)
    create(:job_application, status: "applied", applied_on: sunday - 9)
    application = create(:job_application, status: "hr_interview", applied_on: sunday - 20, responded_on: sunday - 1)
    create(:application_email, job_application: application, category: "interview", received_at: sunday - 1)
    create(:application_email, job_application: application, category: "rejection", received_at: sunday - 3)
    create(:application_email, job_application: application, category: "interview", received_at: sunday - 10)

    expect(summary).to have_attributes(applied: 2, applied_last_week: 1, answers: 2, interviews: 1)
    expect(summary.lines.first).to eq("2 candidaturas · semana passada: 1 · 2 respostas · 1 convite de entrevista")
    expect(summary.lines.last).to start_with("Dica: ")
  end

  it "names the aggregator sources whose jobs you saved" do
    create_list(:job_posting, 5, source: "remotive", triage: "saved", created_at: sunday - 3)
    create_list(:job_posting, 6, source: "extension", triage: "saved", created_at: sunday - 3)
    create(:job_application, status: "applied", applied_on: sunday - 1)

    expect(summary.best_sources).to eq([ "Remotive" ])
    expect(summary.lines).to include("Fontes que mais renderam: Remotive")
  end

  describe "the tip" do
    it "asks to apply when the week had no application, pointing at the saved jobs" do
      expect(summary.tip).to eq("Nenhuma candidatura esta semana. Comece pelas vagas novas de nota mais alta.")

      create_list(:job_posting, 2, triage: "saved")
      expect(described_class.new(today: sunday).tip).to include("as 2 vagas salvas")
    end

    it "asks for the follow-ups due, then points at the origin that answers more" do
      create(:job_application, status: "applied", applied_on: sunday - 1)
      create(:job_application, status: "applied", applied_on: sunday - 10, next_follow_up_on: sunday)
      expect(summary.tip).to eq("1 follow-up pendente: uma mensagem curta costuma reabrir a conversa.")

      JobApplication.update_all(next_follow_up_on: nil)
      create_list(:job_application, 3, origin: "Indicação", status: "hr_interview", applied_on: sunday - 15, responded_on: sunday - 5)
      create_list(:job_application, 5, origin: "LinkedIn", status: "applied", applied_on: sunday - 15)
      expect(described_class.new(today: sunday).tip).to include("via Indicação respondem 100%")
    end

    it "suggests a new approach when few companies answer, and the triage when many jobs wait" do
      create_list(:job_application, 10, origin: "LinkedIn", status: "applied", applied_on: sunday - 3)
      expect(summary.tip).to include("Poucas respostas no mês")

      create_list(:job_application, 2, origin: "LinkedIn", status: "hr_interview", applied_on: sunday - 3, responded_on: sunday - 1)
      create_list(:job_posting, 20)
      expect(described_class.new(today: sunday).tip).to eq("Há 20 vagas novas esperando triagem.")

      JobPosting.update_all(triage: "dismissed")
      expect(described_class.new(today: sunday).tip).to include("Bom ritmo")
    end
  end
end
