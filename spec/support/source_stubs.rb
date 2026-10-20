module SourceStubs
  def stub_source(url, fixture, content_type: "application/json")
    stub_request(:get, url).to_return(status: 200, body: fixture_text("sources/#{fixture}"), headers: { "Content-Type" => content_type })
  end

  # Stubs every aggregator endpoint with the recorded fixtures. Boards of companies discovered
  # during a run answer empty; tests stub specific boards after calling this.
  def stub_all_sources
    stub_request(:get, %r{boards-api\.greenhouse\.io/v1/boards/}).to_return(body: { jobs: [] }.to_json)
    stub_request(:get, %r{api\.lever\.co/v0/postings/}).to_return(body: [].to_json)
    stub_request(:get, %r{api\.ashbyhq\.com/posting-api/job-board/}).to_return(body: { jobs: [] }.to_json)
    stub_request(:get, %r{apply\.workable\.com/api/v1/widget/accounts/}).to_return(body: { jobs: [] }.to_json)
    stub_source("https://remotive.com/api/remote-jobs?search=rails", "remotive.json")
    stub_source("https://remotive.com/api/remote-jobs?search=ruby", "remotive.json")
    stub_source("https://remoteok.com/api", "remote_ok.json")
    stub_source(Sources::WorkingNomads::URL, "working_nomads.json")
    stub_source("https://himalayas.app/jobs/api/search?q=ruby%20on%20rails&page=1", "himalayas.json")
    stub_request(:get, "https://himalayas.app/jobs/api/search?q=ruby%20on%20rails&page=2").to_return(body: { jobs: [] }.to_json)
    stub_source("https://api.remotar.com.br/jobs?search=ruby", "remotar.json")
    stub_source("https://api.remotar.com.br/jobs?search=rails", "remotar.json")
    Sources::WeWorkRemotely::FEEDS.each { stub_source(it, "we_work_remotely.rss", content_type: "application/rss+xml") }
    stub_source("https://api.github.com/repos/backend-br/vagas/issues?state=open&per_page=100", "backend_br.json")
    stub_source("https://api.github.com/repos/frontendbr/vagas/issues?state=open&per_page=100", "frontend_br.json")
    stub_source(Sources::HackerNews::SEARCH_URL, "hn_search.json")
    stub_source("https://hn.algolia.com/api/v1/items/49922569", "hn_item.json")
    stub_source(Sources::GoRails::URL, "gorails.rss", content_type: "application/rss+xml")
  end
end

RSpec.configure do |config|
  config.include SourceStubs
end
