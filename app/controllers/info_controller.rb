class InfoController < ApplicationController
  layout "pages"
  def about
  end
  
  def contact
  end
  
  def frames
  end
  
  def finance
    @pages = Page.paginate(:page => params[:page], :joins => :company, :order => 'monthly_trend DESC', :per_page => APP_CONFIG['articles_per_page'])   
    
    @page = Page.find(:first,  :joins => :company, :order => 'monthly_trend DESC' )
    if @page.nil?
      @page = Page.find(:first)
    end
          
    
    unless params[:page]
      params[:page]='1'
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
