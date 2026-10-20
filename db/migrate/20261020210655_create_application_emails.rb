class CreateApplicationEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :application_emails do |t|
      t.references :job_application, null: false, foreign_key: { on_delete: :cascade }
      t.string :message_id, null: false
      t.string :from_name
      t.string :from_address
      t.string :subject
      t.datetime :received_at
      t.string :category, null: false
      t.text :summary
      t.string :status_before
      t.string :status_after
      t.string :classified_by, null: false

      t.timestamps
    end
    add_index :application_emails, :message_id, unique: true

    add_column :job_applications, :responded_on, :date

    add_column :settings, :track_replies, :boolean, null: false, default: true
    add_column :settings, :replies_checked_at, :datetime
    add_column :settings, :notify_replies, :boolean, null: false, default: true
    add_column :settings, :notify_follow_ups, :boolean, null: false, default: true
  end
end
