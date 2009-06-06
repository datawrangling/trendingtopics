class RemoveCreatedAtFromPage < ActiveRecord::Migration
  def self.up
    remove_column :pages, :created_at
  end

  def self.down
    add_column :pages, :created_at, :datetime
  end
end
