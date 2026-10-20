class CreateProcessedEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :processed_emails do |t|
      t.string :message_id, null: false
      t.string :subject
      t.datetime :received_at
      t.integer :postings_count, null: false, default: 0

      t.timestamps
    end
    add_index :processed_emails, :message_id, unique: true
  end
end
