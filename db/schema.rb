# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150515141952) do

  create_table "alarm_assignations", force: true do |t|
    t.integer  "eartag"
    t.integer  "number_alarm"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "alarms", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "animal_milking_details", force: true do |t|
    t.float    "conductivity"
    t.float    "temperature"
    t.datetime "time_at"
    t.float    "volume"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "animal_milking_id"
    t.float    "flow"
  end

  add_index "animal_milking_details", ["animal_milking_id"], name: "index_animal_milking_details_on_animal_milking_id", using: :btree

  create_table "animal_milkings", force: true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "milking_session_id"
    t.datetime "date_start_at"
    t.datetime "date_end_at"
    t.float    "conductivity"
    t.float    "temperature"
    t.float    "volume"
    t.integer  "eartag"
    t.integer  "meter"
  end

  add_index "animal_milkings", ["milking_session_id"], name: "index_animal_milkings_on_milking_session_id", using: :btree

  create_table "animals", force: true do |t|
    t.datetime "inactivated_at"
    t.string   "long_name"
    t.string   "id_fiscal"
    t.string   "breed"
    t.integer  "weight"
    t.string   "origin"
    t.string   "state"
    t.integer  "tambero_id"
    t.string   "comment_state"
    t.integer  "rp_number"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "male"
    t.integer  "rp_sire"
    t.integer  "rp_dam"
    t.integer  "owner_id"
    t.string   "species_type"
    t.integer  "life_production"
    t.integer  "herd_id"
    t.datetime "birth_date_at"
    t.string   "rfid_tag"
  end

  create_table "api_transfers", force: true do |t|
    t.string   "process_type"
    t.string   "process_name"
    t.datetime "date_at"
    t.boolean  "result"
    t.integer  "code_error"
    t.string   "error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "feeders", force: true do |t|
    t.string   "name"
    t.integer  "number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "heat_tamberos", force: true do |t|
    t.string   "heat_icon"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "eartag"
    t.string   "pregnancy"
  end

  create_table "heats", force: true do |t|
    t.datetime "detected_at"
    t.string   "detected_method"
    t.string   "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "milk_temerature"
    t.integer  "activity"
    t.float    "probability_tambero"
    t.integer  "eartag"
    t.boolean  "confirm"
    t.integer  "milking_session_id"
    t.boolean  "transferred"
  end

  add_index "heats", ["milking_session_id"], name: "index_heats_on_milking_session_id", using: :btree

  create_table "milking_machine_reads", force: true do |t|
    t.integer  "eartag"
    t.float    "volume"
    t.float    "temperature"
    t.float    "conductivity"
    t.string   "state"
    t.float    "flow"
    t.integer  "meter"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "milking_current"
  end

  create_table "milking_machines", force: true do |t|
    t.integer  "number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "milking_sessions", force: true do |t|
    t.datetime "date_at"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notification_messages", force: true do |t|
    t.string   "name"
    t.string   "message"
    t.string   "source"
    t.integer  "code"
    t.boolean  "status"
    t.string   "link"
    t.string   "color"
    t.string   "type_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pedometries", force: true do |t|
    t.integer  "battery"
    t.datetime "dated_at"
    t.integer  "steps_number"
    t.integer  "lying_time"
    t.integer  "walking_time"
    t.integer  "standing_time"
    t.integer  "eartag"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "milking_session_id"
    t.integer  "real_steps"
  end

  add_index "pedometries", ["milking_session_id"], name: "index_pedometries_on_milking_session_id", using: :btree

  create_table "scales", force: true do |t|
    t.integer  "number"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tambero_apis", force: true do |t|
    t.string   "tambero_api_key"
    t.string   "tambero_user_id"
    t.string   "time_zone"
    t.integer  "end_milking"
    t.integer  "min_milking"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "tambero_last_upload_at"
    t.string   "language"
    t.float    "installed_version"
    t.float    "current_version"
    t.integer  "days_without_connexion"
    t.boolean  "pedometry_module"
    t.boolean  "weighing_module"
    t.boolean  "update_pedometer"
    t.float    "per_temperature"
    t.float    "per_activity"
    t.boolean  "heat_module"
    t.integer  "period_between_heats"
  end

  create_table "users", force: true do |t|
    t.string   "crypted_password",          limit: 40
    t.string   "salt",                      limit: 40
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "name"
    t.string   "email_address"
    t.boolean  "administrator",                        default: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                                default: "active"
    t.datetime "key_timestamp"
  end

  add_index "users", ["state"], name: "index_users_on_state", using: :btree

  create_table "weighing_sessions", force: true do |t|
    t.datetime "dated_at"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "weighings", force: true do |t|
    t.date     "dated_at"
    t.string   "hour"
    t.decimal  "weight",              precision: 10, scale: 0
    t.integer  "eartag"
    t.text     "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "weighing_session_id"
  end

  add_index "weighings", ["weighing_session_id"], name: "index_weighings_on_weighing_session_id", using: :btree

end
