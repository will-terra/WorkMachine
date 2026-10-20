require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "connects with a valid session cookie" do
    user = create(:user)
    session = user.sessions.create!

    cookies.signed[:session_id] = session.id
    connect

    expect(connection.current_user).to eq(user)
  end

  it "rejects a connection without a session" do
    expect { connect }.to have_rejected_connection
  end
end
