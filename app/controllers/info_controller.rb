class InfoController < ApplicationController
  layout "pages", :except => [:frames]
  
  caches_page :about 
  
  def about
  end
  
  def contact
  end
  
  def frames
    @page = Page.find_by_url(params[:url])
  end
  
  
  def hourly_trends
    unless params[:page]
      params[:page]='1'
    end    
    unless read_fragment({:page => params[:page]}) 
      @pages = Page.paginate(:page => params[:page], :joins => [ :hourly_trend ], :conditions => ["featured=0"], :order => 'hourly_trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
      @page = Page.find(:first, :joins => [ :hourly_trend ], :conditions => ["featured=0"], :order => 'hourly_trend DESC' )
      if @page.nil?
        @page = Page.find(:first)
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }     
    end    
  end  
  
  
  
  def people
    unless params[:page]
      params[:page]='1'
    end    
    unless read_fragment({:page => params[:page]}) 
      @pages = Page.paginate(:page => params[:page], :joins => [ :person ], :conditions => ["featured=0"], :order => 'daily_trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
      @page = Page.find(:first, :joins => [ :person ], :order => 'daily_trend DESC' )
      if @page.nil?
        @page = Page.find(:first)
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
    end    
  end
  
  def finance
    unless params[:page]
      params[:page]='1'
    end    
    unless read_fragment({:page => params[:page]}) 
      @pages = Page.paginate(:page => params[:page], :joins => [ :company ],:conditions => ["featured=0"], :order => 'daily_trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
      @page = Page.find(:first, :joins => [ :company ], :order => 'daily_trend DESC' )
      if @page.nil?
        @page = Page.find(:first)
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
    end    
  end  
  
  def alphabet
    #this page will display the day's top ranked articles for each letter in the alphabet...
    # A,B,C etc
  end  
  

end
