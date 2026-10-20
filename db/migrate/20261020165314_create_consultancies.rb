class CreateConsultancies < ActiveRecord::Migration[8.1]
  def change
    create_table :consultancies do |t|
      t.string :name, null: false
      t.string :url, null: false
      t.string :kind, null: false
      t.date :registered_on
      t.text :notes

      t.timestamps
    end
    add_index :consultancies, :name, unique: true
  end
end
