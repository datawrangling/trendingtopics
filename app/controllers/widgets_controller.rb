class WidgetsController < ApplicationController
  layout nil
  session :off
  
  def chart_widget
    # get timeline for wikipedia article id
    @page = Page.find(params[:id])
  end
 
end
