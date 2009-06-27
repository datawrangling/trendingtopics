class AddFeaturedToPagesStage < ActiveRecord::Migration
  def self.up
    add_column :new_pages, :featured, :boolean, :default => 0
  end

  def self.down
    remove_column :new_pages, :featured
  end
end
