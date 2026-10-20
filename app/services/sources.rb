# Registry of the aggregator sources, in the order FetchJobsJob runs them.
module Sources
  def self.all
    [ Remotive, RemoteOk, WeWorkRemotely, WorkingNomads, Himalayas, Remotar, BackendBr, FrontendBr, HackerNews, GoRails,
      Greenhouse, Lever, Ashby, Workable ]
  end

  def self.find(key)
    all.find { it.key == key.to_s }
  end
end
