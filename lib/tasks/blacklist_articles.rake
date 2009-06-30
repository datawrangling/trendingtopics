
task :blacklist_articles => :environment do
  APP_CONFIG = YAML.load_file("config/config.yml")["#{RAILS_ENV}"]
  APP_CONFIG['blacklist'].each do |badpage|
    puts badpage
    system "mysql -u root trendingtopics_#{RAILS_ENV} -e 'update pages set featured=1 where id = #{badpage};'"
  end
end  