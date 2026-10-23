# Registry of the aggregator sources, in the order FetchJobsJob runs them.
module Sources
  def self.all
    [ Remotive, RemoteOk, WeWorkRemotely, WorkingNomads, Himalayas, Remotar, Gupy, Programathor, VagasCom, TelegramChannels,
      BackendBr, FrontendBr, HackerNews, GoRails, Greenhouse, Lever, Ashby, Workable ]
  end

  def self.find(key)
    all.find { it.key == key.to_s }
  end

  # The sources that run for this profile: the ones that make sense for it and are not turned
  # off in Ajustes.
  def self.enabled(profile = Profile.current, setting = Setting.current)
    all.select { it.applicable?(profile) && setting.source_enabled?(it.key) }
  end
end
