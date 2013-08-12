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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130812205352) do

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
    t.boolean  "active",             :default => true, :null => false
    t.string   "answered_from"
    t.datetime "answered_at"
    t.string   "last_call_status"
    t.string   "last_voice_number"
    t.integer  "allocated_skill_id"
    t.string   "last_call_sid"
  end

  add_index "candidates", ["allocated_skill_id"], :name => "index_candidates_on_allocated_skill_id"
  add_index "candidates", ["last_call_sid"], :name => "index_candidates_on_last_call_sid"

  create_table "channels", :force => true do |t|
    t.integer  "volunteer_id"
    t.string   "type"
    t.string   "address"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "current_calls", :force => true do |t|
    t.integer  "pigeon_channel_id"
    t.integer  "candidate_id"
    t.string   "session_id"
    t.string   "call_status"
    t.string   "voice_number"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "current_calls", ["candidate_id"], :name => "index_current_calls_on_candidate_id"
  add_index "current_calls", ["pigeon_channel_id"], :name => "index_current_calls_on_pigeon_channel_id"
  add_index "current_calls", ["session_id"], :name => "index_current_calls_on_session_id"
  add_index "current_calls", ["voice_number"], :name => "index_current_calls_on_voice_number"

  create_table "identities", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "token"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "identities", ["provider", "token"], :name => "index_identities_on_provider_and_token"

  create_table "invites", :force => true do |t|
    t.integer  "organization_id"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
  end

  create_table "members", :force => true do |t|
    t.integer  "organization_id"
    t.integer  "user_id"
    t.string   "role"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mission_skills", :force => true do |t|
    t.integer  "mission_id"
    t.integer  "skill_id"
    t.integer  "priority"
    t.integer  "req_vols"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "missions", :force => true do |t|
    t.float    "lat"
    t.float    "lng"
    t.string   "reason"
    t.string   "status"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "name"
    t.integer  "organization_id"
    t.text     "messages"
    t.string   "city"
    t.string   "forward_address"
  end

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "max_sms_retries",   :default => 3
    t.integer  "max_voice_retries", :default => 3
    t.integer  "sms_timeout",       :default => 5
    t.integer  "voice_timeout",     :default => 5
  end

  create_table "pigeon_channels", :force => true do |t|
    t.integer  "organization_id"
    t.string   "name"
    t.string   "description"
    t.string   "channel_type"
    t.string   "pigeon_name"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "enabled",         :default => true
    t.integer  "limit",           :default => 1
  end

  add_index "pigeon_channels", ["organization_id"], :name => "index_pigeon_channels_on_organization_id"

  create_table "skills", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
  end

  create_table "skills_volunteers", :id => false, :force => true do |t|
    t.integer "skill_id"
    t.integer "volunteer_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                                  :default => "", :null => false
    t.string   "encrypted_password",      :limit => 128, :default => ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "invitation_token",        :limit => 60
    t.datetime "invitation_sent_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "current_organization_id"
    t.datetime "invitation_accepted_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token"
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "volunteers", :force => true do |t|
    t.string   "name"
    t.float    "lat"
    t.float    "lng"
    t.string   "address"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "shifts"
    t.integer  "organization_id"
  end

  add_index "volunteers", ["lat", "lng"], :name => "index_volunteers_on_lat_and_lng"

end
