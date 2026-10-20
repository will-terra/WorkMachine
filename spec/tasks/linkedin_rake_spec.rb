require "rails_helper"
require "rake"

RSpec.describe "linkedin rake tasks" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after { Rake::Task.tasks.each(&:reenable) }

  it "parses an exported alert without saving" do
    path = Rails.root.join("spec/fixtures/emails/linkedin_job_alert.eml").to_s

    expect { Rake::Task["linkedin:parse"].invoke(path) }.to output(/Globex.*3 vaga\(s\) encontrada\(s\)/m).to_stdout
    expect(JobPosting.count).to eq(0)
  end

  it "reports when Gmail is not configured" do
    allow(LinkedinAlerts::Importer).to receive(:configured?).and_return(false)

    expect { Rake::Task["linkedin:import"].invoke }.to output(/Gmail não configurado/).to_stdout
  end
end
