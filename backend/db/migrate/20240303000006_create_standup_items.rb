class CreateStandupItems < ActiveRecord::Migration[7.1]
  def change
    create_table :standup_items, id: :uuid do |t|
      t.references :standup, type: :uuid, null: false, foreign_key: true
      t.integer :item_type, null: false
      t.text :content, null: false
      t.integer :sort_order, default: 0, null: false

      t.timestamps
    end

    add_index :standup_items, [:standup_id, :item_type]
  end
end
