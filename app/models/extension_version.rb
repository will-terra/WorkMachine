# The version of the browser extension that ships with this code (extension/manifest.json).
module ExtensionVersion
  STORE_URL = "https://chromewebstore.google.com/detail/lohldenjhfbijbcolpglchnnionlbfaa".freeze

  def self.current
    @current ||= JSON.parse(Rails.root.join("extension/manifest.json").read).fetch("version")
  end
end
