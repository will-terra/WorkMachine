require "rails_helper"
require "rake"

RSpec.describe "jobs rake tasks" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after { Rake::Task.tasks.each(&:reenable) }

  it "fetches and prints a summary" do
    stub_all_sources

    expect { Rake::Task["jobs:fetch"].invoke }.to output(/gorails\s+succeeded/).to_stdout
  end

  it "rescores every posting" do
    posting = create(:job_posting, title: "Ruby on Rails Developer", description: "", location_text: nil, score: 0)

    expect { Rake::Task["jobs:rescore"].invoke }.to output(/1 vagas recalculadas/).to_stdout
    expect(posting.reload.score).to eq(40)
  end
end
