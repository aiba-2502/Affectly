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

ActiveRecord::Schema[8.0].define(version: 2025_01_30_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "period_type", ["session", "daily", "weekly", "monthly"]

  create_table "api_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "encrypted_token", limit: 191, null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encrypted_token"], name: "index_api_tokens_on_encrypted_token", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "chats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "tag_id"
    t.string "title", limit: 120
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_chats_on_tag_id"
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.bigint "sender_id", null: false
    t.text "content", null: false
    t.json "llm_metadata"
    t.decimal "emotion_score", precision: 3, scale: 2
    t.json "emotion_keywords"
    t.datetime "sent_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "sent_at"], name: "idx_messages_chat_sent"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
    t.index ["sent_at"], name: "index_messages_on_sent_at"
    t.check_constraint "emotion_score >= 0::numeric AND emotion_score <= 1::numeric", name: "chk_emotion_score"
  end

  create_table "summaries", force: :cascade do |t|
    t.enum "period", null: false, enum_type: "period_type"
    t.bigint "chat_id"
    t.bigint "user_id"
    t.datetime "tally_start_at", null: false
    t.datetime "tally_end_at", null: false
    t.json "analysis_data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id", "period"], name: "index_summaries_on_chat_id_and_period"
    t.index ["chat_id"], name: "index_summaries_on_chat_id"
    t.index ["user_id", "period", "tally_start_at"], name: "index_summaries_on_user_id_and_period_and_tally_start_at"
    t.index ["user_id"], name: "index_summaries_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "category", limit: 30
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "email", limit: 255, null: false
    t.string "password_digest", limit: 255, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "api_tokens", "users"
  add_foreign_key "chats", "tags"
  add_foreign_key "chats", "users"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "summaries", "chats"
  add_foreign_key "summaries", "users"
end
