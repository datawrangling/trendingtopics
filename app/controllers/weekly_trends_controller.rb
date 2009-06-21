class WeeklyTrendsController < ApplicationController
  # GET /weekly_trends
  # GET /weekly_trends.xml
  # def index
  #   @weekly_trends = WeeklyTrend.all
  # 
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render :xml => @weekly_trends }
  #   end
  # end

  # GET /weekly_trends/1
  # GET /weekly_trends/1.xml
  def show
    @weekly_trend = WeeklyTrend.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @weekly_trend }
    end
  end

end
