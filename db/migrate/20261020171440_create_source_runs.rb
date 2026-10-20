class CreateSourceRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :source_runs do |t|
      t.string :source, null: false
      t.string :status, null: false, default: "running"
      t.integer :fetched_count, null: false, default: 0
      t.integer :created_count, null: false, default: 0
      t.text :error_message
      t.datetime :finished_at

      t.timestamps
    end
    add_index :source_runs, [ :source, :created_at ]
  end
end
