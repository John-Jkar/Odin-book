class CreateRelationships < ActiveRecord::Migration[8.1]
  def change
    create_table :relationships do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :following, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :relationships, [ :follower_id, :following_id ], unique: true
    add_index :relationships, [ :following_id, :status ]
  end
end
