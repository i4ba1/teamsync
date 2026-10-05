class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :timezone, default: "UTC", null: false
      t.string :avatar_url
      t.integer :status, default: 0, null: false
      t.integer :role, default: 1, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :status
    add_index :users, :deleted_at
  end
end
