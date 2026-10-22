require "rails_helper"
require "rake"

RSpec.describe "extension rake tasks" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after { Rake::Task.tasks.each(&:reenable) }

  it "zips the extension with the manifest at the root and without the README" do
    output = Rails.root.join("tmp/extension-spec.zip")

    expect { Rake::Task["extension:zip"].invoke(output.to_s) }.to output(/versão #{Regexp.escape(ExtensionVersion.current)}/).to_stdout

    names = Zip::File.open(output.to_s) { |zip| zip.map(&:name) }
    expect(names).to include("manifest.json", "popup.html", "service-worker.js", "icons/icon-128.png", "fonts/OFL.txt")
    expect(names).not_to include("README.md")
  ensure
    output&.delete if output&.exist?
  end
end
