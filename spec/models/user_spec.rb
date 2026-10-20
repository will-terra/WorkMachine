require "rails_helper"

RSpec.describe User do
  it "normalizes the email address" do
    user = create(:user, email_address: "  Ana@Example.COM ")

    expect(user.email_address).to eq("ana@example.com")
  end

  it "requires a password with at least 8 characters" do
    user = build(:user, password: "curta")

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "rejects a duplicated email address" do
    create(:user, email_address: "ana@example.com")

    expect(build(:user, email_address: "ANA@example.com")).not_to be_valid
  end
end
