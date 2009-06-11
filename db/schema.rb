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

ActiveRecord::Schema.define(:version => 20090611190137) do

  create_table "daily_timelines", :force => true do |t|
    t.integer  "page_id"
    t.text     "dates"
    t.text     "pageviews"
    t.integer  "total_pageviews"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "daily_timelines", ["total_pageviews"], :name => "timeline_totalviews_index"

  create_table "daily_trends", :force => true do |t|
    t.integer  "page_id"
    t.float    "trend"
    t.float    "error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "daily_trends", ["page_id", "trend"], :name => "daily_trends_index"

  create_table "new_daily_timelines", :force => true do |t|
    t.integer  "page_id"
    t.text     "dates"
    t.text     "pageviews"
    t.integer  "total_pageviews"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "new_daily_trends", :force => true do |t|
    t.integer  "page_id"
    t.float    "trend"
    t.float    "error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "new_pages", :force => true do |t|
    t.string  "url"
    t.string  "title"
    t.integer "page_latest"
    t.integer "total_pageviews"
    t.float   "monthly_trend"
  end

  create_table "pages", :force => true do |t|
    t.string  "url"
    t.string  "title"
    t.integer "page_latest"
    t.integer "total_pageviews"
    t.float   "monthly_trend"
  end

  add_index "pages", ["title"], :name => "pages_title_index"

  create_table "weekly_trends", :force => true do |t|
    t.integer  "page_id"
    t.float    "trend"
    t.float    "error"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
