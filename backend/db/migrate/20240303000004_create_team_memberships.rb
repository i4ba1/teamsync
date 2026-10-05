class CreateTeamMemberships < ActiveRecord::Migration[7.1]
  def change
    create_table :team_memberships, id: :uuid do |t|
      t.references :team, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.integer :role, default: 2, null: false
      t.datetime :joined_at, null: false

      t.timestamps
    end

    add_index :team_memberships, [:team_id, :user_id], unique: true
  end
end
