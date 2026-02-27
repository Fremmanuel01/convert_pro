class CreateConversions < ActiveRecord::Migration[8.1]
  def change
    create_table :conversions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tool_name
      t.integer :status
      t.text :error_message
      t.float :processing_time

      t.timestamps
    end
  end
end
