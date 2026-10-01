class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_column :users, :full_name, :string
    add_column :users, :location, :string
    add_column :users, :bio, :text
    add_column :users, :website, :string
    add_column :users, :birth_date, :date

    add_index :users, :username, unique: true
  end
end
