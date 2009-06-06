require 'active_record/fixtures'
 
namespace :db do
  desc "Seed the database with once/ and always/ fixtures."
  task :seed => :environment do 
    load_fixtures "data/once"
    load_fixtures "data/always", :always
  end
 
  desc "Seed the database with develop/ fixtures."
  task :develop => :environment do 
    load_fixtures 'data/develop', :always
  end
 
 
  private
 
  def load_fixtures(dir, always = false)
    Dir.glob(File.join(RAILS_ROOT, 'db', dir, '*.yml')).each do |fixture_file|
      table_name = File.basename(fixture_file, '.yml')
 
      if table_empty?(table_name) || always
        truncate_table(table_name)
        Fixtures.create_fixtures(File.join('db/', dir), table_name)
      end
    end
  end  
 
  def table_empty?(table_name)
    quoted = connection.quote_table_name(table_name)
    connection.select_value("SELECT COUNT(*) FROM #{quoted}").to_i.zero?
  end
 
  def truncate_table(table_name)
    quoted = connection.quote_table_name(table_name)
    connection.execute("DELETE FROM #{quoted}")
  end
 
  def connection
    ActiveRecord::Base.connection
  end
end

