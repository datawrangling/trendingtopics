class CreateHourlyTimelinesStagingTable < ActiveRecord::Migration
  def self.up
    create_table "new_hourly_timelines", :force => true do |t|
      t.integer  "page_id"
      t.text     "datetimes"
      t.text     "pageviews"
    end
              
    add_index "hourly_timelines", ["page_id"], :name => "hourly_timelines_page_index"
    add_index "new_hourly_timelines", ["page_id"], :name => "hourly_timelines_page_index"    
    
  end

  def self.down
    remove_index "new_hourly_timelines", "hourly_timelines_page_index"
    remove_index "hourly_timelines", "hourly_timelines_page_index"
    drop_table :new_hourly_timelines    
  end
end
