desc 'Purge fragment and page caches after daily load'
 
task :purge_cache => :environment do
  ActionController::Base.new.expire_fragment(%r{/pages.*})
  ActionController::Base.new.expire_fragment(%r{/info.*})
  # to expire page caches, we remove the directories in /public on web server
  exec "rm -rf public/pages"
  exec "rm -rf public/page"
  exec "rm -rf public/info"    
end