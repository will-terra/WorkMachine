class CreateRoutines < ActiveRecord::Migration[8.1]
  def change
    create_table :routines do |t|
      t.string :name, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :routine_slots do |t|
      t.references :routine, null: false, foreign_key: true
      t.string :title, null: false
      t.string :time
      t.string :period, null: false, default: "daily"
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :routine_items do |t|
      t.references :routine_slot, null: false, foreign_key: true
      t.string :key, null: false, index: { unique: true }
      t.text :label, null: false
      t.string :url
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_column :settings, :routines_seeded_at, :datetime
  end
end
