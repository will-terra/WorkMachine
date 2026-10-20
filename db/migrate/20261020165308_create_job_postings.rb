class CreateJobPostings < ActiveRecord::Migration[8.1]
  def change
    create_table :job_postings do |t|
      t.string :title, null: false
      t.string :company
      t.string :url, null: false
      t.string :fingerprint, null: false
      t.string :source, null: false
      t.string :external_id
      t.string :location_text
      t.string :remote_scope, null: false, default: "unknown"
      t.text :description
      t.string :salary_text
      t.datetime :posted_at
      t.integer :score, null: false, default: 0
      t.json :matched_keywords, null: false, default: []
      t.string :seniority, null: false, default: "unknown"
      t.string :triage, null: false, default: "new"
      t.json :raw, null: false, default: {}

      t.timestamps
    end
    add_index :job_postings, :url, unique: true
    add_index :job_postings, :fingerprint
    add_index :job_postings, [ :triage, :score ]
    add_index :job_postings, [ :source, :external_id ]
  end
end
