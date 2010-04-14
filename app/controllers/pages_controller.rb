class PagesController < ApplicationController
  # GET /pages
  protect_from_forgery :only => [:create, :update, :destroy]
  layout 'pages', :except => [:image] #, :except => [:auto_complete_for_search_query]
  use_google_charts

  caches_page :show
  caches_page :csv  
  

  def auto_complete_for_search_query
    # look for autosuggest results in memcached
    unless read_fragment({:query => params["search"]["query"]}) 
      @pages = Page.title_like params["search"]["query"]
    end
    render :partial => "search_results"
  end  
  
  #[http://localhost:3000/pages/image?pageurl=LeBron_James
  def image
    @page = Page.find_by_url(params["pageurl"])
    pic_url = @page.picture
    send_data "#{pic_url}", :type => 'text/html; charset=utf-8'
  end  
  
    
  def index
    if params[:search]
      @pages = Page.title_like(params["search"]["query"]).paginate(:page => params[:page], :order => 'monthly_trend DESC', :per_page => APP_CONFIG['articles_per_page'])  
    else   
      @pages = Page.paginate(:page => params[:page], :conditions => ["featured=0"], :order => 'monthly_trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
    end 
  
    # random rising, rotates
    @page = Page.find(:all, :limit => APP_CONFIG['articles_per_page'] , :order => 'daily_trend DESC', :conditions => ["featured=0"] ).rand  
      
    unless params[:page]
      params[:page]='1'
    end  
      
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
      format.atom { render :layout => false}
    end      
  end

  # GET /pages/1
  # GET /pages/1.xml
 
  def show
    @range=60
    @page = Page.find_by_url(params[:url].join('/'))
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @page }
    end
  end
  
#### Custom REST actions #######  


end
