ActionController::Routing::Routes.draw do |map|
  map.resources :weekly_trends

  map.resources :daily_trends

  map.root :controller => "pages"  
  map.resources :daily_timelines
  
  map.connect "sitemap.xml", :controller => "sitemap", :action => "sitemap"
                                                  
  map.resources :pages, :member => {:csv => :get  }, :collection => {:auto_complete_for_search_query => :get }

  # map.connect '/pages/auto_complete_for_search_query', :controller => 'pages', :action => 'auto_complete_for_search_query'
  # map.connect '/pages/:url', :controller => 'pages', :action => 'find_by_url',
  #                                               :url => /.*/
  # map.connect '/pages', :controller => 'pages', :action => 'index'                                       

  map.connect '/widgets/:chart_widget/:id', :controller => 'widgets', :action => 'chart_widget'


  map.with_options :controller => 'info' do |info|
    info.about 'about', :action => 'about'
    info.contact 'contact', :action => 'contact'
    info.frames 'frames', :action => 'frames' 
    info.finance 'finance', :action => 'finance'   
    info.auto_complete_for_search_query 'pages/auto_complete_for_search_query', :action => 'auto_complete_for_search_query'     
  end
  
  

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
