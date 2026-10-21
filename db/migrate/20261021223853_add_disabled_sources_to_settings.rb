class AddDisabledSourcesToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :disabled_sources, :json, null: false, default: []
  end
end
