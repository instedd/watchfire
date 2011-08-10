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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110810162057) do

  create_table "candidates", :force => true do |t|
    t.integer  "mission_id"
    t.integer  "volunteer_id"
    t.string   "status"
    t.integer  "voice_retries"
    t.integer  "sms_retries"
    t.datetime "last_voice_att"
    t.datetime "last_sms_att"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "call_id"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "missions", :force => true do |t|
    t.integer  "req_vols"
    t.float    "lat"
    t.float    "lng"
    t.string   "reason"
    t.string   "status"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "volunteers", :force => true do |t|
    t.string   "name"
    t.float    "lat"
    t.float    "lng"
    t.string   "address"
    t.string   "voice_number"
    t.string   "sms_number"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "volunteers", ["lat", "lng"], :name => "index_volunteers_on_lat_and_lng"

end
