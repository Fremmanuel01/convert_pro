class ChangeUserIdNullOnConversions < ActiveRecord::Migration[7.1]
  def change
    change_column_null :conversions, :user_id, true
  end
end
