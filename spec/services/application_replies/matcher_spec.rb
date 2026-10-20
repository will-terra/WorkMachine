require "rails_helper"

RSpec.describe ApplicationReplies::Matcher do
  let!(:fcamara) { create(:job_application, company: "Grupo FCamara", role: "Dev Ruby", status: "applied") }
  let!(:sierra) { create(:job_application, company: "Sierra Studio", role: "Rails Engineer", status: "hr_interview") }

  def match(from_name: "", from_address: "x@example.com", subject: "")
    described_class.new.match(from_name:, from_address:, subject:)
  end

  it "matches the company in the sender name, the subject or the sender domain" do
    expect(match(from_name: "FCamara Talentos")).to eq(fcamara)
    expect(match(subject: "Sua candidatura na Sierra Studio")).to eq(sierra)
    expect(match(from_address: "recruiting@fcamara.com.br")).to eq(fcamara)
  end

  it "ignores other companies, closed and only-saved applications" do
    create(:job_application, company: "Rejeitada", status: "rejected")
    create(:job_application, company: "Salva", status: "saved")

    expect(match(subject: "Newsletter da Acme")).to be_nil
    expect(match(subject: "Rejeitada: novidades")).to be_nil
    expect(match(subject: "Salva: oi")).to be_nil
  end

  it "prefers the application whose role is in the subject" do
    backend = create(:job_application, company: "Sierra Studio", role: "Backend Ruby", status: "applied")

    expect(match(subject: "Sierra Studio · Backend Ruby: update")).to eq(backend)
  end
end
