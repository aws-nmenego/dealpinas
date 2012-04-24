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

ActiveRecord::Schema.define(:version => 20120418151126) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "categories", :primary_key => "category_id", :force => true do |t|
    t.string   "category_name"
    t.string   "code"
    t.string   "icon_image"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deal_category_mappings", :force => true do |t|
    t.integer  "deal_id"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deal_locations", :primary_key => "location_id", :force => true do |t|
    t.string   "location_name"
    t.decimal  "latitude",      :precision => 8, :scale => 5
    t.decimal  "longitude",     :precision => 8, :scale => 5
    t.integer  "deal_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deals", :primary_key => "deal_id", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.datetime "expiry"
    t.integer  "no_of_items_sold"
    t.integer  "quantity"
    t.decimal  "original_price",   :precision => 16, :scale => 8, :default => 0.0,   :null => false
    t.decimal  "price",            :precision => 16, :scale => 8, :default => 0.0,   :null => false
    t.string   "discount"
    t.string   "deal_url"
    t.string   "deal_thumb"
    t.string   "rss_deal_id"
    t.integer  "category_id"
    t.string   "author"
    t.string   "merchant_name"
    t.string   "contact_name"
    t.string   "contact_number"
    t.string   "contact_email"
    t.string   "contact_address"
    t.string   "contact_url"
    t.boolean  "is_ad",                                           :default => false, :null => false
    t.string   "promo"
    t.boolean  "support_print"
    t.string   "permit"
    t.datetime "display_until"
    t.string   "status",                                          :default => "",    :null => false
    t.boolean  "reviewed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", :force => true do |t|
    t.integer  "deal_id"
    t.string   "url"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sale_details", :primary_key => "sales_id", :force => true do |t|
    t.integer  "deal_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sales", :primary_key => "sales_id", :force => true do |t|
    t.datetime "purchase_date"
    t.decimal  "total_amount",  :precision => 10, :scale => 0
    t.integer  "quantity"
    t.string   "status"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "searches", :force => true do |t|
    t.string   "keywords"
    t.integer  "category_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tags", :force => true do |t|
    t.integer  "category_id"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_types", :force => true do |t|
    t.string   "type_name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "user_name"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company_name"
    t.string   "site_url"
    t.string   "encrypted_password"
    t.string   "salt"
    t.integer  "user_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
