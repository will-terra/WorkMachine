require "rails_helper"

# The extension's texts live in extension/_locales (chrome.i18n): every language has the same keys,
# and every key the pages and scripts use exists.
RSpec.describe "extension locales" do
  root = Rails.root.join("extension")
  messages = %w[en pt_BR pt_PT].index_with { JSON.parse(root.join("_locales/#{it}/messages.json").read) }

  it "has the same keys in every language" do
    expect(messages.values.map(&:keys).uniq.size).to eq(1)
  end

  it "has a text for every key the extension uses" do
    used = root.glob("*.js").flat_map { it.read.scan(/\bt\("(\w+)"/).flatten + it.read.scan(/\bt\([^()]*?\? "(\w+)" : "(\w+)"/).flatten }
    used += root.glob("*.html").flat_map { it.read.scan(/data-i18n(?:-[a-z-]+)?="(\w+)"/).flatten }
    used += JSON.parse(root.join("manifest.json").read).to_s.scan(/__MSG_(\w+)__/).flatten

    expect(used.uniq - messages["en"].keys).to eq([])
    expect(used).to include("alreadyInPartial", "markApplied", "description")
  end
end
