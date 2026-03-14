class AddConfirmableAndAdminToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :confirmation_token,    :string
    add_column :users, :confirmed_at,          :datetime
    add_column :users, :confirmation_sent_at,  :datetime
    add_column :users, :unconfirmed_email,     :string
    add_column :users, :admin,                 :boolean, default: false, null: false

    add_index :users, :confirmation_token, unique: true

    # Confirm all existing users so they are not locked out
    User.update_all(confirmed_at: Time.current)
  end

  def down
    remove_index :users, :confirmation_token
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email
    remove_column :users, :admin
  end
end
