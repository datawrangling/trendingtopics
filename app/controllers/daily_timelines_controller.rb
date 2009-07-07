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
  # GET /daily_timelines/Michael_Jackson.csv
  def show    
    @daily_timeline = DailyTimeline.find(params[:id])
    @page = @daily_timeline.page

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @daily_timeline }
      format.csv {
        puts params[:url] 
        csv_array = ["Date,Pageviews"]
        @page.date_pageview_array.each do |pair|
          csv_array << "#{pair[0]},#{pair[1]}"
        end
        send_data csv_array.join("\n"), :type => 'text/csv; charset=utf-8', :filename=>"#{@page.url}.csv",
        :disposition => 'attachment'
      }
    end
  end

end
