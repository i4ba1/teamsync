class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :timezone, default: "UTC", null: false
      t.time :standup_time, default: "09:00", null: false
      t.integer :standup_days, array: true, default: [1, 2, 3, 4, 5], null: false
      t.references :created_by, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.jsonb :settings, default: {}, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :teams, :slug, unique: true
    add_index :teams, :created_by_id
    add_index :teams, :deleted_at
  end
end
