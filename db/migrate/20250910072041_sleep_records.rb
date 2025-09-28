class SleepRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :sleep_records do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :sleep_at, null: false
      t.datetime :wake_up_at
      t.integer :duration_in_seconds
      t.timestamps
      t.index [ :user_id, :created_at ]
    end
  end
end
