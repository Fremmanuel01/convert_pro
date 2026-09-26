class Conversion < ApplicationRecord
  belongs_to :user, optional: true

  has_many_attached :input_files
  has_one_attached :output_file

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending

  validates :tool_name, presence: true

  # Refund the single quota unit this conversion consumed, at most once.
  #
  # The conditional UPDATE on usage_counted is the concurrency guard: only one
  # caller (the first BaseTool failure path OR the ToolJob retry-exhaustion
  # handler) can flip the flag, so a unit is never refunded twice even if
  # several failure paths run for the same conversion.
  def refund_usage!
    return false unless usage_counted?

    flipped = self.class.where(id: id, usage_counted: true)
                        .update_all(usage_counted: false) == 1
    return false unless flipped

    self.usage_counted = false
    ConversionLimiter.new(user).refund! if user_id.present?
    true
  end
end
