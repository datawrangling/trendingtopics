class DailyTrendsController < ApplicationController
  # GET /daily_trends
  # GET /daily_trends.xml
  layout "pages", :except => [:rss] 
  
  
  def feed
    @daily_trends = DailyTrend.find(:all, :limit => 20,:conditions => ["page_id NOT IN (?)", APP_CONFIG['blacklist']], :order => 'trend DESC')
  end  
  
    
  def index
    # @daily_trends = DailyTrend.find(:all, :limit => 20,:conditions => ["page_id NOT IN (?)", APP_CONFIG['blacklist']], :order => 'trend DESC')
    @pages = Page.paginate(:page => params[:page], :joins => [:daily_trend ], :conditions => ["pages.id NOT IN (?) and featured=0", APP_CONFIG['blacklist']], :order => 'daily_trends.trend DESC', :per_page => APP_CONFIG['articles_per_page'])       
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @daily_trends }
      format.rss { render :layout => false}
    end
  end

  # GET /daily_trends/1
  # GET /daily_trends/1.xml
  def show
    @daily_trend = DailyTrend.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @daily_trend }
    end
  end

end
