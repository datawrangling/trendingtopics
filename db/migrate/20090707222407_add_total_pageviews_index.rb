class AddTotalPageviewsIndex < ActiveRecord::Migration
  def self.up
    add_index "pages", ["title", "featured", "total_pageviews"], :name => "pages_title_pageviews_index"
    add_index "new_pages", ["title", "featured", "total_pageviews"], :name => "pages_title_pageviews_index"
  end

  def self.down
    remove_index "pages", "pages_title_pageviews_index"
    remove_index "new_pages", "pages_title_pageviews_index"  
  end
end
