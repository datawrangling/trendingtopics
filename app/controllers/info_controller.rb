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
  end  
  
  def alphabet
    #this page will display the day's top ranked articles for each letter in the alphabet...
    # A,B,C etc
  end  

end
