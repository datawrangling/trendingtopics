class CreateDailyTimelines < ActiveRecord::Migration
  def self.up
    create_table :daily_timelines do |t|
      t.references :page
      t.text :dates
      t.text :pageviews
      t.integer :total_pageviews

      t.timestamps
    end
  end

  def self.down
    drop_table :daily_timelines
  end
end
