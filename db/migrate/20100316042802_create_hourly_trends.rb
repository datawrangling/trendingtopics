class CreateHourlyTrends < ActiveRecord::Migration
  def self.up
    create_table :hourly_trends do |t|
      t.float :hourly_trend
      t.references :page
      t.timestamps
    end
    
    create_table :new_hourly_trends do |t|
      t.float :hourly_trend
      t.references :page
      t.timestamps
    end    
    
    add_index "hourly_trends", ["page_id", "hourly_trend"], :name => "hourly_trend_index"
    add_index "new_hourly_trends", ["page_id", "hourly_trend"], :name => "hourly_trend_index"    
  end

  def self.down
    remove_index "hourly_trends", "hourly_trend_index"
    remove_index "new_hourly_trends", "hourly_trend_index"
    drop_table :hourly_trends
    drop_table :new_hourly_trends    
  end
end
