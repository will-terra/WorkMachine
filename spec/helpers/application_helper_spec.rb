require "rails_helper"

RSpec.describe ApplicationHelper do
  it "shows WSL paths as Windows paths" do
    expect(helper.windows_path("/mnt/c/Users/ana/Documents/WorkMachine/backups")).to eq("C:\\Users\\ana\\Documents\\WorkMachine\\backups")
    expect(helper.windows_path("./backups")).to eq("./backups")
  end
end
