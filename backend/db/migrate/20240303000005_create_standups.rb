class CreateStandups < ActiveRecord::Migration[7.1]
  def change
    create_table :standups, id: :uuid do |t|
      t.references :team, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.date :standup_date, null: false
      t.integer :status, default: 0, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :standups, [:team_id, :standup_date]
    add_index :standups, [:user_id, :standup_date], unique: true
    add_index :standups, :status
  end
end
