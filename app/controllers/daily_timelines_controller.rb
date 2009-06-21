class DailyTimelinesController < ApplicationController
  # GET /daily_timelines
  # GET /daily_timelines.xml

    
  # def index
  #   @daily_timelines = DailyTimeline.all
  # 
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render :xml => @daily_timelines }
  #   end
  # end

  # GET /daily_timelines/1
  # GET /daily_timelines/1.xml
  def show
    @daily_timeline = DailyTimeline.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @daily_timeline }
    end
  end

end
