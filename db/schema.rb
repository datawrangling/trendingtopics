# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090627203556) do

  create_table "companies", :force => true do |t|
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "companies", ["page_id"], :name => "companies_page_index"

  create_table "daily_timelines", :force => true do |t|
    t.integer  "page_id"
    t.text     "dates"
    t.text     "pageviews"
    t.integer  "total_pageviews"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "daily_timelines", ["page_id"], :name => "daily_timelines_page_index"

  create_table "featured_pages", :force => true do |t|
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "featured_pages", ["page_id"], :name => "featured_pages_page_index"

  create_table "new_daily_timelines", :force => true do |t|
    t.integer  "page_id"
    t.text     "dates"
    t.text     "pageviews"
    t.integer  "total_pageviews"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "new_daily_timelines", ["page_id"], :name => "daily_timelines_page_index"

  create_table "new_daily_trends", :force => true do |t|
    t.integer  "page_id"
    t.float    "trend"
    t.float    "error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "new_featured_pages", :force => true do |t|
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "new_featured_pages", ["page_id"], :name => "featured_pages_page_index"

  create_table "new_pages", :force => true do |t|
    t.string  "url"
    t.string  "title"
    t.integer "page_latest"
    t.integer "total_pageviews"
    t.float   "monthly_trend"
    t.boolean "featured",        :default => false
    t.float   "daily_trend"
  end

  add_index "new_pages", ["featured", "daily_trend"], :name => "pages_feature_daily_trend_index"
  add_index "new_pages", ["featured", "monthly_trend"], :name => "pages_feature_monthly_trend_index"
  add_index "new_pages", ["title", "featured", "daily_trend"], :name => "pages_title_daily_trend_index"
  add_index "new_pages", ["title", "featured", "monthly_trend"], :name => "pages_title_monthly_trend_index"
  add_index "new_pages", ["url"], :name => "pages_url_index"

  create_table "pages", :force => true do |t|
    t.string  "url"
    t.string  "title"
    t.integer "page_latest"
    t.integer "total_pageviews"
    t.float   "monthly_trend"
    t.boolean "featured",        :default => false
    t.float   "daily_trend"
  end

  add_index "pages", ["featured", "daily_trend"], :name => "pages_feature_daily_trend_index"
  add_index "pages", ["featured", "monthly_trend"], :name => "pages_feature_monthly_trend_index"
  add_index "pages", ["title", "featured", "daily_trend"], :name => "pages_title_daily_trend_index"
  add_index "pages", ["title", "featured", "monthly_trend"], :name => "pages_title_monthly_trend_index"
  add_index "pages", ["url"], :name => "pages_url_index"

  create_table "people", :force => true do |t|
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "people", ["page_id"], :name => "people_page_index"

end
