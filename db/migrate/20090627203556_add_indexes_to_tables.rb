class AddIndexesToTables < ActiveRecord::Migration
  def self.up
    add_index "companies", ["page_id"], :name => "companies_page_index"
    add_index "people", ["page_id"], :name => "people_page_index"
    
    add_index "featured_pages", ["page_id"], :name => "featured_pages_page_index"
    add_index "daily_timelines", ["page_id"], :name => "daily_timelines_page_index"
    add_index "pages", ["url"], :name => "pages_url_index"
    add_index "pages", ["title",  "featured", "daily_trend"], :name => "pages_title_daily_trend_index"
    add_index "pages", ["title", "featured", "monthly_trend"], :name => "pages_title_monthly_trend_index"
    add_index "pages", ["featured", "daily_trend"], :name => "pages_feature_daily_trend_index"
    add_index "pages", ["featured", "monthly_trend"], :name => "pages_feature_monthly_trend_index"
    
    add_index "new_featured_pages", ["page_id"], :name => "featured_pages_page_index"
    add_index "new_daily_timelines", ["page_id"], :name => "daily_timelines_page_index"
    add_index "new_pages", ["url"], :name => "pages_url_index"
    add_index "new_pages", ["title",  "featured", "daily_trend"], :name => "pages_title_daily_trend_index"
    add_index "new_pages", ["title", "featured", "monthly_trend"], :name => "pages_title_monthly_trend_index"
    add_index "new_pages", ["featured", "daily_trend"], :name => "pages_feature_daily_trend_index"
    add_index "new_pages", ["featured", "monthly_trend"], :name => "pages_feature_monthly_trend_index"    
    
  end

  def self.down
    remove_index "companies", "companies_page_index"
    remove_index "people", "people_page_index"
    
    remove_index "featured_pages", "featured_pages_page_index"
    remove_index "daily_timelines", "daily_timelines_page_index"
    remove_index "pages", "pages_url_index"
    remove_index "pages", "pages_title_daily_trend_index"
    remove_index "pages", "pages_title_monthly_trend_index"
    remove_index "pages", "pages_feature_daily_trend_index"
    remove_index "pages", "pages_feature_monthly_trend_index"    

    remove_index "new_featured_pages", "featured_pages_page_index"
    remove_index "new_daily_timelines", "daily_timelines_page_index"
    remove_index "new_pages", "pages_url_index"
    remove_index "new_pages", "pages_title_daily_trend_index"
    remove_index "new_pages", "pages_title_monthly_trend_index"
    remove_index "new_pages", "pages_feature_daily_trend_index"
    remove_index "new_pages", "pages_feature_monthly_trend_index"    
    
  end
end
