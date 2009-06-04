class CreateDailyTrends < ActiveRecord::Migration
  def self.up
    create_table :daily_trends do |t|
      t.references :page
      t.float :trend
      t.float :error

      t.timestamps
    end
  end

  def self.down
    drop_table :daily_trends
  end
end
