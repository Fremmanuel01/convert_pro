class AddUsageAccountingToConversions < ActiveRecord::Migration[8.1]
  def change
    # Whether this conversion has consumed one unit of the user's quota.
    # Lets us refund exactly once on failure without double-counting.
    add_column :conversions, :usage_counted, :boolean, default: false, null: false

    # Client-generated idempotency key for browser-side conversions, so repeated
    # / replayed accounting posts for the same operation never double-charge.
    add_column :conversions, :client_operation_id, :string
    add_index  :conversions, :client_operation_id, unique: true
  end
end
