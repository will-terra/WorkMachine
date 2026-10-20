class CreateAiArtifacts < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_artifacts do |t|
      t.references :job_posting, null: false, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.string :language
      t.text :content
      t.string :model
      t.integer :input_tokens
      t.integer :output_tokens
      t.text :error_message

      t.timestamps
    end
    add_index :ai_artifacts, [ :job_posting_id, :kind ]
  end
end
