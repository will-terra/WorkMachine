require "rails_helper"

RSpec.describe "Job applications" do
  before { sign_in }

  describe "GET /candidaturas" do
    it "shows the kanban with one column per status" do
      create(:job_application, company: "Acme", status: "applied")

      get job_applications_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Entrevista técnica", "Acme", 'data-controller="kanban"')
    end

    it "shows the table filtered by status and search" do
      create(:job_application, company: "Acme", status: "applied")
      create(:job_application, company: "Globex", status: "applied")
      create(:job_application, company: "Acme Labs", status: "rejected")

      get job_applications_path(view: "table", status: "applied", q: "acm")

      expect(response.body).to include("Acme")
      expect(response.body).not_to include("Globex", "Acme Labs")
    end

    it "exports the spreadsheet as .xlsx" do
      create(:job_application, company: "Acme", role: "Rails Dev", contact_url: "https://acme.com/jobs/1")

      get job_applications_path(format: :xlsx)

      expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      expect(response.headers["Content-Disposition"]).to include("candidaturas-")
      zip = Zip::File.open_buffer(StringIO.new(response.body))
      expect(zip.read("xl/worksheets/sheet1.xml")).to include("Acme", "Rails Dev")
      expect(zip.read("xl/workbook.xml")).to include("Resumo")
    end

    it "exports CSV" do
      create(:job_application, company: "Acme")

      get job_applications_path(format: :csv)

      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include("empresa,vaga", "Acme")
    end
  end

  it "creates an application" do
    get new_job_application_path(status: "applied")
    expect(response.body).to include('selected="selected" value="applied"')

    expect {
      post job_applications_path, params: { job_application: { company: "Acme", role: "Rails Dev", status: "applied" } }
    }.to change(JobApplication, :count).by(1)

    expect(response).to redirect_to(job_applications_path)
    expect(JobApplication.last.applied_on).to eq(Date.current)
  end

  it "re-renders the form on invalid data" do
    post job_applications_path, params: { job_application: { company: "", role: "" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates and returns to the table" do
    application = create(:job_application)

    get edit_job_application_path(application)
    expect(response).to have_http_status(:ok)

    patch job_application_path(application), params: { job_application: { notes: "Ligar sexta" }, return_view: "table" }

    expect(response).to redirect_to(job_applications_path(view: "table"))
    expect(application.reload.notes).to eq("Ligar sexta")
  end

  it "keeps the form on invalid update" do
    application = create(:job_application)

    patch job_application_path(application), params: { job_application: { company: "" } }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "deletes an application" do
    application = create(:job_application)

    expect { delete job_application_path(application) }.to change(JobApplication, :count).by(-1)
  end

  describe "PATCH /candidaturas/:id/move" do
    it "moves the card and answers with Turbo Streams" do
      card = create(:job_application, status: "saved")
      create(:job_application, status: "applied")

      patch move_job_application_path(card), params: { status: "applied", position: 0 }, as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("column_count_saved", "column_count_applied", dom_id(card))
      expect(card.reload).to have_attributes(status: "applied", position: 0, applied_on: Date.current)
    end

    it "rejects an unknown status" do
      card = create(:job_application)

      patch move_job_application_path(card), params: { status: "hired", position: 0 }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /candidaturas/import" do
    it "imports a CSV file" do
      file = fixture_file_upload("candidaturas_excel.csv", "text/csv")

      expect { post import_job_applications_path, params: { file: } }.to change(JobApplication, :count).by(2)
      expect(flash[:notice]).to eq("2 candidatura(s) importada(s).")
      expect(flash[:alert]).to include("Linha 4")
    end

    it "asks for a file" do
      post import_job_applications_path

      expect(flash[:alert]).to eq("Escolha um arquivo CSV.")
    end
  end

  def dom_id(record) = ActionView::RecordIdentifier.dom_id(record)
end
