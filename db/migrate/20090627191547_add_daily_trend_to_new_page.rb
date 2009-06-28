class AddDailyTrendToNewPage < ActiveRecord::Migration
  def self.up
    add_column :new_pages, :daily_trend, :float
  end

  def self.down
    remove_column :new_pages, :daily_trend
  end
end
