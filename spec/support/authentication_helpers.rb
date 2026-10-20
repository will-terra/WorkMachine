module AuthenticationHelpers
  def sign_in(user = create(:user))
    post session_path, params: { email_address: user.email_address, password: user.password }
    user
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
