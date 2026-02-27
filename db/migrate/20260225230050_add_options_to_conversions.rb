class AddOptionsToConversions < ActiveRecord::Migration[8.1]
  def change
    add_column :conversions, :options, :jsonb
  end
end
