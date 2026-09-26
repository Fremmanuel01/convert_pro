class CreateAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :analytics_events do |t|
      t.string  :name, null: false          # e.g. "conversion_started"
      t.bigint  :user_id                     # nullable: anonymous events
      t.string  :anonymous_id                # scoped session id for guests
      t.string  :tool_id                     # e.g. "compress_pdf"
      t.string  :plan                        # "free" / "pro" at event time
      t.boolean :authenticated, default: false, null: false
      t.jsonb   :properties, default: {}, null: false  # never document contents/filenames
      t.datetime :created_at, null: false
    end

    add_index :analytics_events, :name
    add_index :analytics_events, :created_at
    add_index :analytics_events, [:name, :created_at]
    add_index :analytics_events, :user_id
  end
end
