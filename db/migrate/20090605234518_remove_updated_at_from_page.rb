class RemoveUpdatedAtFromPage < ActiveRecord::Migration
  def self.up
    remove_column :pages, :updated_at
  end

  def self.down
    add_column :pages, :updated_at, :datetime
  end
end
