require "rails_helper"

RSpec.describe Radar do
  it "has every search with a known builder" do
    expect(described_class.searches).not_to be_empty
    expect(described_class.searches.map { it.fetch("builder") }.uniq - Radar::BUILDERS).to be_empty
  end

  it "has a default for every filter used by a section" do
    used = described_class.sections.flat_map { it.fetch("filters", []) }.uniq

    expect(used).to all(satisfy { described_class.filters.dig(it, "default") })
  end

  describe ".url_for" do
    let(:filters) { described_class.default_filters }

    it "builds LinkedIn job searches with the chosen region and period" do
      url = described_class.url_for("li_jobs", '"ruby on rails"', filters.merge("li_region" => "rs", "li_period" => "r604800"))

      expect(url).to eq("https://www.linkedin.com/jobs/search/?keywords=%22ruby%20on%20rails%22&location=Paran%C3%A1%2C%20Brasil&f_TPR=r604800&sortBy=DD")
    end

    it "forces worldwide remote for the LATAM search" do
      expect(described_class.url_for("li_jobs_world", "rails", filters)).to include("geoId=92000000&f_WT=2")
    end

    it "builds the other searches" do
      expect(described_class.url_for("li_posts", "rails", filters)).to include("datePosted=%22past-24h%22", "sortBy=%22date_posted%22")
      expect(described_class.url_for("li_people_br", "rails", filters)).to include("geoUrn=%5B%22106057199%22%5D")
      expect(described_class.url_for("li_people", "rails", filters)).to end_with("keywords=rails")
      expect(described_class.url_for("google", "rails", filters)).to end_with("&tbs=qdr:w")
      expect(described_class.url_for("google", "rails", filters.merge("g_period" => ""))).to eq("https://www.google.com/search?q=rails")
      expect(described_class.url_for("google_jobs", "rails", filters)).to end_with("&ibp=htl;jobs")
      expect(described_class.url_for("x", "rails", filters)).to eq("https://x.com/search?q=rails&src=typed_query&f=live")
    end

    it "rejects an unknown builder" do
      expect { described_class.url_for("bing", "rails", filters) }.to raise_error(ArgumentError)
    end
  end

  it "sanitizes filter values" do
    expect(described_class.sanitize_filters("li_region" => "world_remote", "g_period" => "evil"))
      .to include("li_region" => "world_remote", "g_period" => "w", "post_period" => "past-24h")
  end
end
