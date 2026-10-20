class CreateTargetCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :target_companies do |t|
      t.string :name, null: false
      t.string :ats, null: false
      t.string :board_slug, null: false
      t.boolean :active, null: false, default: true
      t.boolean :example, null: false, default: false
      t.datetime :last_fetched_at

      t.timestamps
    end
    add_index :target_companies, [ :ats, :board_slug ], unique: true
  end
end
