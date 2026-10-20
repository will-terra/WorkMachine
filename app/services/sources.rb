# Registry of the aggregator sources, in the order FetchJobsJob runs them.
module Sources
  def self.all
    [ Remotive, RemoteOk, WeWorkRemotely, BackendBr, FrontendBr, HackerNews, GoRails, Greenhouse, Lever, Ashby ]
  end

  def self.find(key)
    all.find { it.key == key.to_s }
  end
end
