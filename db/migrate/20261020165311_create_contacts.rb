class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :company
      t.string :linkedin_url
      t.string :kind, null: false, default: "recruiter"
      t.date :last_contacted_on
      t.text :notes

      t.timestamps
    end
    add_index :contacts, :linkedin_url, unique: true, where: "linkedin_url IS NOT NULL"
  end
end
