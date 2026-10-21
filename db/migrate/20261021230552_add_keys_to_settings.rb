class AddKeysToSettings < ActiveRecord::Migration[8.1]
  def change
    change_table :settings, bulk: true do |t|
      t.text :openrouter_api_key
      t.string :openrouter_model
      t.text :gmail_user
      t.text :gmail_app_password
      t.text :api_token
      t.datetime :onboarded_at
    end
  end
end
