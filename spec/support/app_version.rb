# Ajustes asks GitHub for the latest release; specs answer "no release" unless they stub it.
RSpec.configure do |config|
  config.before { stub_request(:get, AppVersion::RELEASES_URL).to_return(status: 404, body: "{}") }
end
