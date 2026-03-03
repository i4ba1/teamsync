class AddTeamInviteCode < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :invite_code, :string
    add_column :teams, :invite_code_expires_at, :datetime
    
    add_index :teams, :invite_code, unique: true
  end
end
