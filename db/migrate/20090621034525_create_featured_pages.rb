class CreateFeaturedPages < ActiveRecord::Migration
  def self.up
    create_table :featured_pages do |t|
      t.references :page

      t.timestamps
    end
  end

  def self.down
    drop_table :featured_pages
  end
end
