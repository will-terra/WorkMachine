class CreateRoutineChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :routine_checks do |t|
      t.date :date, null: false
      t.string :item_key, null: false

      t.timestamps
    end
    add_index :routine_checks, [ :date, :item_key ], unique: true
  end
end
