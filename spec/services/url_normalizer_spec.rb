require "rails_helper"

RSpec.describe UrlNormalizer do
  it "canonicalizes LinkedIn job links" do
    expect(described_class.call("https://br.linkedin.com/comm/jobs/view/4012345678/?trackingId=abc&refId=x"))
      .to eq("https://www.linkedin.com/jobs/view/4012345678")
    expect(described_class.call("https://www.linkedin.com/jobs/view/ruby-developer-at-acme-4012345678"))
      .to eq("https://www.linkedin.com/jobs/view/4012345678")
    expect(described_class.call("https://www.linkedin.com/jobs/search/?currentJobId=4012345678&keywords=rails"))
      .to eq("https://www.linkedin.com/jobs/view/4012345678")
  end

  it "drops tracking params, fragments and trailing slashes" do
    expect(described_class.call("HTTP://Jobs.Lever.co/acme/123/?utm_source=x&lever-source=LinkedIn#apply"))
      .to eq("https://jobs.lever.co/acme/123")
  end

  it "keeps meaningful params, sorted" do
    expect(described_class.call("https://acme.com/careers?gh_jid=42&b=2&utm_medium=email"))
      .to eq("https://acme.com/careers?b=2&gh_jid=42")
  end

  it "leaves non-http values alone" do
    expect(described_class.call("  mailto:jobs@acme.com ")).to eq("mailto:jobs@acme.com")
    expect(described_class.call("http://exa mple.com")).to eq("http://exa mple.com")
    expect(described_class.call(nil)).to eq("")
  end
end
