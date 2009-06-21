class PagesController < ApplicationController
  # GET /pages
  protect_from_forgery :only => [:create, :update, :destroy]
  layout 'pages'#, :except => [:auto_complete_for_search_query]
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
    
  def index
    if params[:search]
      @pages = Page.title_like(params["search"]["query"]).paginate(:page => params[:page], :order => 'monthly_trend DESC', :per_page => APP_CONFIG['articles_per_page'])  
    else   
      @pages = Page.paginate(:page => params[:page], :conditions => ["pages.id NOT IN (?) and featured=0", APP_CONFIG['blacklist']], :order => 'monthly_trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
    end 
  
    # random rising, rotates
    @page = DailyTrend.find(:all, :limit => 20 , :order => 'trend DESC', :conditions => ["page_id NOT IN (?) and page_id NOT IN (select page_id from featured_pages)", APP_CONFIG['blacklist']] ).rand.page   
      
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
    @page = Page.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @page }
    end
  end
  
#### Custom REST actions #######  
  
  # GET /pages/1/csv
  def csv
    @page = Page.find(params[:id]) 
    csv_array = ["Date,Pageviews"]
    @page.date_pageview_array.each do |pair|
      csv_array << "#{pair[0]},#{pair[1]}"
    end
    send_data csv_array.join("\n"), :type => 'text/csv; charset=utf-8', :filename=>"#{@page.url}.csv",
    :disposition => 'attachment'
    
  end  

end
