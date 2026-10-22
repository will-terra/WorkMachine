class AddLocaleToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :locale, :string, null: false, default: "auto"
    add_column :settings, :detected_locale, :string
  end
end
