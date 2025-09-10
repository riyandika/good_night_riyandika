class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.timestamps

      add_index :users, :name
    end
  end
end
