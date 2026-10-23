require "rails_helper"

RSpec.describe CompanyName do
  it "matches the same company written in different ways" do
    keys = [ "Nimbus Labs", "nimbus labs Inc.", "Nimbus Labs (Brasil)", "NIMBUS LABS LTDA", "Nimbus Labs S.A." ].map { described_class.key(it) }

    expect(keys.uniq).to eq([ "nimbus labs" ])
    expect(described_class.key("Vela Saúde")).to eq(described_class.key("vela saude"))
  end

  it "keeps a name made only of a suffix and ignores blank names" do
    expect(described_class.key("Group")).to eq("group")
    expect(described_class.key(nil)).to be_nil
    expect(described_class.key(" ")).to be_nil
  end
end
