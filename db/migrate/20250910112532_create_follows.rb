class CreateFollows < ActiveRecord::Migration[8.0]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users } # User who follows
      t.references :followee, null: false, foreign_key: { to_table: :users } # User being followed
      t.timestamps

      t.index [:follower_id, :followee_id], unique: true
    end
  end
end
