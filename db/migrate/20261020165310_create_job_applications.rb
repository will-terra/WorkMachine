class CreateJobApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :job_applications do |t|
      t.references :job_posting, foreign_key: { on_delete: :nullify }
      t.string :company, null: false
      t.string :role, null: false
      t.string :origin
      t.string :status, null: false, default: "saved"
      t.date :applied_on
      t.date :next_follow_up_on
      t.string :contact_name
      t.string :contact_url
      t.string :salary_range
      t.text :notes
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :job_applications, [ :status, :position ]
    add_index :job_applications, :next_follow_up_on
  end
end
