class AddMonthlyTrendToPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :monthly_trend, :float
  end

  def self.down
    remove_column :pages, :monthly_trend
  end
end
