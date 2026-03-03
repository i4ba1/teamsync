class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :team, type: :uuid, foreign_key: true
      t.integer :notification_type, null: false
      t.string :title, null: false
      t.text :message, null: false
      t.jsonb :data, default: {}, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, :created_at
  end
end
