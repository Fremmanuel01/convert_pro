class Conversion < ApplicationRecord
  belongs_to :user, optional: true

  has_many_attached :input_files
  has_one_attached :output_file

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending

  validates :tool_name, presence: true
end
