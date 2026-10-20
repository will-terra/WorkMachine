class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.boolean :notifications_enabled, null: false, default: true
      t.integer :notify_min_score, null: false, default: 40
      t.string :vapid_public_key
      t.string :vapid_private_key

      t.timestamps
    end
  end
end
