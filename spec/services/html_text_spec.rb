require "rails_helper"

RSpec.describe HtmlText do
  it "keeps paragraphs and list items" do
    html = "<p>We use <b>Rails</b>.</p><ul><li>Hotwire</li><li>Sidekiq</li></ul><script>alert(1)</script>Line<br>break&nbsp;here"

    expect(described_class.call(html)).to eq("We use Rails.\n• Hotwire\n• Sidekiq\n\nLine\nbreak here")
  end

  it "repairs UTF-8 decoded as Latin-1" do
    expect(described_class.call("Lemon.io â\u0080\u0094 the marketplace")).to eq("Lemon.io — the marketplace")
  end

  it "leaves mixed text alone when it cannot be repaired" do
    expect(described_class.fix_mojibake("— \u0080")).to eq("— \u0080")
  end

  it "returns an empty string for blank input" do
    expect(described_class.call(nil)).to eq("")
  end
end
