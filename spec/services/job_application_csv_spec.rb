require "rails_helper"

RSpec.describe JobApplicationCsv do
  describe ".import" do
    it "imports an Excel CSV with Portuguese headers, labels and dates" do
      result = described_class.import(fixture_text("files/candidaturas_excel.csv"))

      expect(result.created).to eq(2)
      expect(result.errors).to contain_exactly(
        a_string_including("Linha 4", "status desconhecido"),
        a_string_including("Linha 6", "Vaga")
      )
      acme = JobApplication.find_by!(company: "Acme")
      expect(acme).to have_attributes(status: "applied", applied_on: Date.new(2026, 10, 15), contact_url: "https://acme.com/jobs/1", notes: "Indicação da Ana")
      expect(JobApplication.find_by!(company: "Globex")).to have_attributes(status: "tech_interview", next_follow_up_on: Date.new(2026, 10, 22))
    end

    it "accepts English attribute names, a BOM and an empty status" do
      result = described_class.import("﻿company,role,status\nAcme,Rails Dev,\n")

      expect(result.created).to eq(1)
      expect(JobApplication.last.status).to eq("saved")
    end

    it "reports invalid dates" do
      result = described_class.import("empresa,vaga,aplicou_em\nAcme,Dev,31/02/2026\n")

      expect(result.errors.first).to include("data inválida")
    end

    it "reports a malformed file" do
      result = described_class.import("empresa,vaga\n\"Acme,Dev\n")

      expect(result.created).to eq(0)
      expect(result.errors.first).to include("Arquivo CSV inválido")
    end
  end

  describe ".export" do
    it "round-trips through import" do
      posting = create(:job_posting, url: "https://jobs.example.com/42")
      create(:job_application, company: "Acme", role: "Dev", status: "offer", applied_on: Date.new(2026, 10, 1), job_posting: posting)

      csv = described_class.export(JobApplication.all)
      JobApplication.delete_all
      result = described_class.import(csv)

      expect(csv).to start_with(JobApplicationCsv::BOM)
      expect(result.created).to eq(1)
      expect(JobApplication.last).to have_attributes(company: "Acme", status: "offer", applied_on: Date.new(2026, 10, 1), contact_url: "https://jobs.example.com/42")
    end
  end
end
