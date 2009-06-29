desc 'Purge fragment and page caches after daily load'
 
task :purge_cache => :environment do
  # # won't work with memcached
  # ActionController::Base.new.expire_fragment(%r{/pages.*})
  # ActionController::Base.new.expire_fragment(%r{/info.*})
  
  ActionController::Base.cache_store.clear
   
  # ActiveSupport::Cache::MemCacheStore.new.clear  
  
  # to expire filesystem page caches, we remove the directories in /public on web server
  exec "rm -rf public/pages"
  exec "rm -rf public/page"
  exec "rm -rf public/info"    
end