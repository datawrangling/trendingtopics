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
    @page = @hourly_timeline.page    

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @hourly_timeline }
      format.csv {
        puts params[:url] 
        csv_array = ["Datetime,Pageviews"]
        @page.datetime_pageview_array.each do |pair|
          csv_array << "#{pair[0]},#{pair[1]}"
        end
        send_data csv_array.join("\n"), :type => 'text/csv; charset=utf-8', :filename=>"Hourly_#{@page.url}.csv",
        :disposition => 'attachment'
      }      
      
    end
  end

end
