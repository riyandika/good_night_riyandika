class AddIndexesToSleepRecords < ActiveRecord::Migration[8.0]
  def change
    # Index for in_progress scope: finding records where wake_up_at IS NULL
    # Used in clock in/out functionality
    add_index :sleep_records, [ :user_id, :wake_up_at ],
              name: 'index_sleep_records_on_user_id_and_wake_up_at'

    # Index for friends_sleep_records query: filtering by sleep_at date range
    # Used when finding sleep records within past week
    add_index :sleep_records, [ :sleep_at ],
              name: 'index_sleep_records_on_sleep_at'

    # Index for friends_sleep_records query: ordering by duration
    # Used when sorting friends' sleep records by duration DESC
    add_index :sleep_records, [ :duration_in_seconds ],
              name: 'index_sleep_records_on_duration_in_seconds'

    # Composite index for the most complex query in friends_sleep_records
    # Covers: user_id IN (...) AND sleep_at BETWEEN ... AND wake_up_at IS NOT NULL
    # ORDER BY duration_in_seconds DESC
    add_index :sleep_records, [ :user_id, :sleep_at, :wake_up_at, :duration_in_seconds ],
              name: 'index_sleep_records_composite_friends_query'
  end
end
