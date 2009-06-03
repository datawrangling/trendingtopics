class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      t.string :url
      t.string :title
      t.integer :page_latest
      t.integer :total_pageviews

      t.timestamps
    end
  end

  def self.down
    drop_table :pages
  end
end
