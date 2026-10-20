class CreateMessageTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :message_templates do |t|
      t.string :name, null: false
      t.string :language, null: false, default: "pt"
      t.text :body, null: false
      t.integer :max_chars

      t.timestamps
    end
    add_index :message_templates, :name, unique: true
  end
end
