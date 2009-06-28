class AddDailyTrendToPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :daily_trend, :float
  end

  def self.down
    remove_column :pages, :daily_trend
  end
end
