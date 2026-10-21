# The version of the browser extension that ships with this code (extension/manifest.json).
module ExtensionVersion
  def self.current
    @current ||= JSON.parse(Rails.root.join("extension/manifest.json").read).fetch("version")
  end
end
