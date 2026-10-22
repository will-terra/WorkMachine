require "rails_helper"

RSpec.describe Radar do
  it "has every search with a known builder" do
    expect(described_class.searches).not_to be_empty
    expect(described_class.searches.map { it.fetch("builder") }.uniq - Radar::BUILDERS).to be_empty
  end

  it "has a default for every filter used by a section" do
    used = described_class.tasks.flat_map { it.fetch("filters", []) }.uniq

    expect(used).to all(satisfy { described_class.filters.dig(it, "default") })
  end

  describe ".url_for" do
    let(:filters) { described_class.default_filters }

    it "builds LinkedIn job searches with the chosen region and period" do
      url = described_class.url_for("li_jobs", '"ruby on rails"', filters.merge("li_region" => "local", "li_period" => "r604800"), location: "Curitiba, PR")

      expect(url).to eq("https://www.linkedin.com/jobs/search/?keywords=%22ruby%20on%20rails%22&location=Curitiba%2C%20PR&f_TPR=r604800&sortBy=DD")
      expect(described_class.url_for("li_jobs", "rails", filters.merge("li_region" => "local"))).to include("geoId=106057199&f_TPR")
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

  describe ".automated" do
    it "lists the automated sources with their latest runs" do
      SourceRun.create!(source: "greenhouse", status: "succeeded", created_count: 3, created_at: 2.hours.ago)
      SourceRun.create!(source: "lever", status: "failed", error_message: "HttpClient::Error: 404", created_at: 1.hour.ago)

      automated = described_class.automated
      targets = automated.find { it.name == "Empresas-alvo" }

      expect(automated.flat_map(&:sources)).to match_array(Sources.all.map(&:key) + %w[linkedin_alert application_replies])
      expect(targets).to have_attributes(app_link: :target_companies_path, created_count: 3, failed: true, error_message: "HttpClient::Error: 404")
      expect(targets.last_run_at).to be_within(1.second).of(1.hour.ago)
      expect(automated.find { it.name == "Remotive" }).to have_attributes(last_run_at: nil, interval: 6.hours, off: false)
    end

    it "marks the sources turned off in Ajustes" do
      Setting.current.update!(disabled_sources: %w[remotive])

      automated = described_class.automated

      expect(automated.find { it.name == "Remotive" }.off).to be(true)
      expect(automated.find { it.name == "Alertas do LinkedIn" }.off).to be(false)
    end

    it "knows how often each source runs and which one needs Gmail" do
      expect(described_class.interval_for("linkedin_alert")).to eq(1.hour)
      expect(described_class.interval_for("hacker_news")).to eq(12.hours)
      expect(described_class.interval_for("remote_ok")).to eq(3.hours)
      expect(described_class.automated.select(&:needs_gmail?).map(&:name)).to eq([ "Alertas do LinkedIn", "Respostas das empresas" ])
    end

    it "keeps automated sources out of the manual tasks" do
      manual = described_class.tasks.flat_map { it.fetch("links", []) }.map { it["name"] }
      automated_names = described_class.config.fetch("automated").map { it["name"] }

      expect(manual & automated_names).to be_empty
    end
  end

  describe ".tasks_for" do
    let(:profile) { Profile.current }

    it "fills the searches with the profile and keeps a key and the template for each" do
      searches = described_class.searches_for(profile)

      expect(searches.size).to eq(described_class.searches.size)
      expect(searches.map { it["key"] }).to all(be_present)
      expect(searches.map { it["key"] }.uniq.size).to eq(searches.size)
      contratando = searches.find { it["key"] == "feed_contratando" }
      expect(contratando).to include("query" => 'Rails AND (vaga OR contratando OR "estamos contratando")', "custom" => false)
      expect(contratando["template"]).to include("{{stack}}")
      expect(searches.map { it["query"] }.join).not_to include("{{")
    end

    it "uses the profile's own query for a search" do
      profile.update!(search_overrides: { "feed_contratando" => "minha busca {{stack}}" })

      search = described_class.searches_for(profile).find { it["key"] == "feed_contratando" }
      expect(search).to include("query" => "minha busca Rails", "custom" => true)
    end

    it "leaves out the searches and links that do not apply" do
      data = build(:profile, primary_area: "data", plan_b_area: nil, plan_b_terms: [], domains: [], search_terms: [],
                             skills: [ { "name" => "Python", "level" => "essential" } ])
      keys = described_class.searches_for(data).map { it["key"] }

      expect(keys).not_to include("alert_plano_b", "alert_setores", "alert_skills")
      sites = described_class.tasks_for(data).find { it["key"] == "sites" }["links"].map { it["name"] }
      expect(sites).not_to include("Ruby on Remote")
      expect(described_class.tasks_for(profile).find { it["key"] == "sites" }["links"].map { it["name"] }).to include("Ruby on Remote")
    end

    it "renders the texts and escapes the URLs" do
      telegram = described_class.tasks_for(profile).find { it["key"] == "telegram" }
      expect(telegram["action"]).to include("“rails” e “ruby”")

      indeed = described_class.tasks_for(profile).find { it["key"] == "sites" }["links"].find { it["name"] == "Indeed Brasil" }
      expect(indeed["url"]).to eq("https://br.indeed.com/jobs?q=Desenvolvedora%20Ruby%20on%20Rails")
      expect(described_class.automated.find { it.name == "Remotive" }.note).to start_with("Buscas por “rails” e “ruby”")
    end

    it "gives the terms for the platform profiles" do
      expect(described_class.profile_keywords(profile)).to eq(
        "titles" => [ "Desenvolvedora Ruby on Rails", "Ruby on Rails Developer", "Full Stack Engineer" ],
        "skills" => %w[Rails Ruby React Hotwire],
        "plan_b" => [ "React", "TypeScript", "Next.js" ]
      )
    end
  end

  it "groups every task under a known cadence" do
    cadences = described_class.cadences.map { it["key"] }

    expect(described_class.tasks.map { it["cadence"] }.uniq - cadences).to be_empty
    expect(described_class.tasks.map { it["key"] }).to include("feed", "telegram", "google", "linkedin_alerts", "cadastros")
  end

  it "sanitizes filter values" do
    expect(described_class.sanitize_filters("li_region" => "world_remote", "g_period" => "evil"))
      .to include("li_region" => "world_remote", "g_period" => "w", "post_period" => "past-24h")
  end
end
