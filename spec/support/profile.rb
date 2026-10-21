# Most specs score and search postings for a Rails + React profile; specs about an empty
# installation delete it.
RSpec.configure do |config|
  config.before do
    Current.profile = nil
    create(:profile)
  end
end
