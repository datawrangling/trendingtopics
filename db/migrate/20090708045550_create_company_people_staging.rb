class CreateCompanyPeopleStaging < ActiveRecord::Migration
  def self.up    
    create_table "new_companies", :force => true do |t|
      t.integer  "page_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    create_table "new_people", :force => true do |t|
      t.integer  "page_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end    

    add_index "new_companies", ["page_id"], :name => "companies_page_index"    
    add_index "new_people", ["page_id"], :name => "people_page_index"
     
  end

  def self.down
    drop_table :new_companies
    drop_table :new_people
  end
end
