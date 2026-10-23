class CreateActivatedAlerts < ActiveRecord::Migration[8.1]
  def change
    create_table :activated_alerts do |t|
      t.string :search_key, null: false
      t.string :query, null: false
      t.timestamps
    end
    add_index :activated_alerts, :query, unique: true
  end
end
