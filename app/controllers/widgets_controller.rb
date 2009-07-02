class WidgetsController < ApplicationController
  layout nil
  session :off
  

  def daily_chart_widget    
    # get daily timeline chart for wikipedia article id
    unless params[:range]
      params[:range]=30
    end
    @page = Page.find(params[:id])
    @range = params[:range].to_i
  end
 
end
