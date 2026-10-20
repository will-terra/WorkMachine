module FixtureHelpers
  def fixture_text(path)
    Rails.root.join("spec/fixtures", path).read
  end
end

RSpec.configure do |config|
  config.include FixtureHelpers
end
