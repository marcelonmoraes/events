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

ActiveRecord::Schema[8.1].define(version: 2026_02_19_100000) do
  create_table "events_events", force: :cascade do |t|
    t.integer "actor_id"
    t.string "actor_type"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.json "metadata", default: {}
    t.string "name", null: false
    t.integer "parent_id"
    t.string "request_id"
    t.string "source", default: "manual"
    t.integer "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["actor_type", "actor_id"], name: "index_events_events_on_actor"
    t.index ["created_at"], name: "index_events_events_on_created_at"
    t.index ["name"], name: "index_events_events_on_name"
    t.index ["parent_id"], name: "index_events_events_on_parent_id"
    t.index ["source"], name: "index_events_events_on_source"
    t.index ["target_type", "target_id"], name: "index_events_events_on_target"
  end

  create_table "posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "events_events", "events_events", column: "parent_id"
end
