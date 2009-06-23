class InfoController < ApplicationController
  layout "pages"
  def about
  end
  
  def contact
  end
  
  def frames
  end
  
  
  def people
    unless params[:page]
      params[:page]='1'
    end    
    unless read_fragment({:page => params[:page]}) 
      @pages = Page.paginate(:page => params[:page], :joins => [ :person, :daily_trend], :order => 'daily_trends.trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
      @page = Page.find(:first, :joins => [ :person, :daily_trend], :order => 'daily_trends.trend DESC' )
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
      @pages = Page.paginate(:page => params[:page], :joins => [ :company,  :daily_trend], :order => 'daily_trends.trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
      @page = Page.find(:first, :joins => [ :company,  :daily_trend ], :order => 'daily_trends.trend DESC' )
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
