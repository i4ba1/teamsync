# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_03_03_000009) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "team_id"
    t.integer "notification_type", null: false
    t.string "title", null: false
    t.text "message", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_notifications_on_created_at"
    t.index ["team_id"], name: "index_notifications_on_team_id"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "refresh_tokens", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.string "device_info"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "standup_items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "standup_id", null: false
    t.integer "item_type", null: false
    t.text "content", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["standup_id", "item_type"], name: "index_standup_items_on_standup_id_and_item_type"
    t.index ["standup_id"], name: "index_standup_items_on_standup_id"
  end

  create_table "standups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "user_id", null: false
    t.date "standup_date", null: false
    t.integer "status", default: 0, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_standups_on_status"
    t.index ["team_id", "standup_date"], name: "index_standups_on_team_id_and_standup_date"
    t.index ["team_id"], name: "index_standups_on_team_id"
    t.index ["user_id", "standup_date"], name: "index_standups_on_user_id_and_standup_date", unique: true
    t.index ["user_id"], name: "index_standups_on_user_id"
  end

  create_table "team_memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "team_id", null: false
    t.uuid "user_id", null: false
    t.integer "role", default: 2, null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id", "user_id"], name: "index_team_memberships_on_team_id_and_user_id", unique: true
    t.index ["team_id"], name: "index_team_memberships_on_team_id"
    t.index ["user_id"], name: "index_team_memberships_on_user_id"
  end

  create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "timezone", default: "UTC", null: false
    t.time "standup_time", default: "2000-01-01 09:00:00", null: false
    t.integer "standup_days", default: [1, 2, 3, 4, 5], null: false, array: true
    t.uuid "created_by_id", null: false
    t.jsonb "settings", default: {}, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invite_code"
    t.datetime "invite_code_expires_at"
    t.index ["created_by_id"], name: "index_teams_on_created_by_id"
    t.index ["deleted_at"], name: "index_teams_on_deleted_at"
    t.index ["invite_code"], name: "index_teams_on_invite_code", unique: true
    t.index ["slug"], name: "index_teams_on_slug", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "timezone", default: "UTC", null: false
    t.string "avatar_url"
    t.integer "status", default: 0, null: false
    t.integer "role", default: 1, null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["status"], name: "index_users_on_status"
  end

  add_foreign_key "notifications", "teams"
  add_foreign_key "notifications", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "standup_items", "standups"
  add_foreign_key "standups", "teams"
  add_foreign_key "standups", "users"
  add_foreign_key "team_memberships", "teams"
  add_foreign_key "team_memberships", "users"
  add_foreign_key "teams", "users", column: "created_by_id"
end
