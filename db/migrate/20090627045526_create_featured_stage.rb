class CreateFeaturedStage < ActiveRecord::Migration
  def self.up
    create_table :new_featured_pages do |t|
      t.references :page
      t.timestamps  
    end
        
  end

  def self.down
      drop_table :new_featured_pages
  end
end
