require "rails_helper"

RSpec.describe "Closed jobs" do
  before { sign_in }

  it "flags a job that left the company's board in the list, the job and the application card" do
    posting = create(:job_posting, title: "Rails Engineer", closed_at: Time.zone.local(2026, 10, 21, 9))
    create(:job_application, job_posting: posting, company: "Acme", status: "applied")

    get job_postings_path
    expect(response.body).to include("encerrada", "Saiu do quadro da empresa em 21/10")

    get job_posting_path(posting)
    expect(response.body).to include("Esta vaga saiu do quadro da empresa em 21/10: provavelmente foi encerrada.")

    get job_applications_path(view: "board")
    expect(response.body).to include("vaga encerrada")
  end
end
