require "rails_helper"
require "rake"

RSpec.describe "target_companies rake task" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after { Rake::Task.tasks.each(&:reenable) }

  it "lists the companies added" do
    allow(TargetCompanyFinder).to receive(:call).and_return([ build(:target_company, name: "Kit", ats: "ashby", board_slug: "kit") ])

    expect { Rake::Task["target_companies:find"].invoke }.to output(/\+ Kit \(Ashby: kit\).*1 empresa/m).to_stdout
  end
end
