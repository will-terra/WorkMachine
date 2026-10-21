# The installed version (VERSION, or APP_VERSION set when the image is built) and, once a day, the
# latest release on GitHub, so Ajustes can say when there is something new to install.
module AppVersion
  RELEASES_URL = "https://api.github.com/repos/will-terra/WorkMachine/releases/latest".freeze
  RELEASES_PAGE = "https://github.com/will-terra/WorkMachine/releases".freeze

  module_function

  def current
    ENV["APP_VERSION"].presence&.delete_prefix("v") || Rails.root.join("VERSION").read.strip
  end

  def latest
    Rails.cache.fetch("app-version-latest", expires_in: 12.hours, skip_nil: true) do
      HttpClient.get_json(RELEASES_URL)["tag_name"].to_s.delete_prefix("v").presence
    end
  rescue HttpClient::Error, SocketError, SystemCallError, Timeout::Error, JSON::ParserError
    nil
  end

  def update_available?
    (version = latest) && Gem::Version.new(version) > Gem::Version.new(current)
  rescue ArgumentError
    false
  end
end
