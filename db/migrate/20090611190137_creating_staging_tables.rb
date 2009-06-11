class CreatingStagingTables < ActiveRecord::Migration
  def self.up
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
      
  end

  def self.down
    drop_table :new_pages
    drop_table :new_daily_trends
    drop_table :new_daily_timelines
  end
end
