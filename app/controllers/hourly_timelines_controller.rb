class HourlyTimelinesController < ApplicationController
  # # GET /hourly_timelines
  # # GET /hourly_timelines.xml
  
  # def index
  #   @hourly_timelines = HourlyTimeline.all
  # 
  #   respond_to do |format|
  #     format.html # index.html.erb
  #     format.xml  { render :xml => @hourly_timelines }
  #   end
  # end

  # GET /hourly_timelines/1
  # GET /hourly_timelines/1.xml
  def show
    @hourly_timeline = HourlyTimeline.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @hourly_timeline }
    end
  end

end
