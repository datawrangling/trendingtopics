class CreateHourlyTimelines < ActiveRecord::Migration
  def self.up
    create_table :hourly_timelines do |t|
      t.references :page
      t.text :datetimes
      t.text :pageviews
    end
  end

  def self.down
    drop_table :hourly_timelines
  end
end
