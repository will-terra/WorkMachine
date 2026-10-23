class AddManualFetchAtToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :manual_fetch_at, :datetime
  end
end
