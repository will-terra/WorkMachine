class AddDismissedSuggestionsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :dismissed_suggestions, :json, default: [], null: false
  end
end
