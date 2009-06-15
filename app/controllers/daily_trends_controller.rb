class DailyTrendsController < ApplicationController
  # GET /daily_trends
  # GET /daily_trends.xml
  layout "pages", :except => [:rss] 
  
  
  def feed
    @daily_trends = DailyTrend.find(:all, :limit => 20,:conditions => ["page_id NOT IN (?)", APP_CONFIG['blacklist']], :order => 'trend DESC')
  end  
  
    
  def index
    @daily_trends = DailyTrend.find(:all, :limit => 20,:conditions => ["page_id NOT IN (?)", APP_CONFIG['blacklist']], :order => 'trend DESC')
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @daily_trends }
      format.rss { render :layout => false}
    end
  end

  # GET /daily_trends/1
  # GET /daily_trends/1.xml
  def show
    @daily_trend = DailyTrend.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @daily_trend }
    end
  end

  # # GET /daily_trends/new
  # # GET /daily_trends/new.xml
  # def new
  #   @daily_trend = DailyTrend.new
  # 
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render :xml => @daily_trend }
  #   end
  # end
  # 
  # # GET /daily_trends/1/edit
  # def edit
  #   @daily_trend = DailyTrend.find(params[:id])
  # end
  # 
  # # POST /daily_trends
  # # POST /daily_trends.xml
  # def create
  #   @daily_trend = DailyTrend.new(params[:daily_trend])
  # 
  #   respond_to do |format|
  #     if @daily_trend.save
  #       flash[:notice] = 'DailyTrend was successfully created.'
  #       format.html { redirect_to(@daily_trend) }
  #       format.xml  { render :xml => @daily_trend, :status => :created, :location => @daily_trend }
  #     else
  #       format.html { render :action => "new" }
  #       format.xml  { render :xml => @daily_trend.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # # PUT /daily_trends/1
  # # PUT /daily_trends/1.xml
  # def update
  #   @daily_trend = DailyTrend.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @daily_trend.update_attributes(params[:daily_trend])
  #       flash[:notice] = 'DailyTrend was successfully updated.'
  #       format.html { redirect_to(@daily_trend) }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @daily_trend.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # # DELETE /daily_trends/1
  # # DELETE /daily_trends/1.xml
  # def destroy
  #   @daily_trend = DailyTrend.find(params[:id])
  #   @daily_trend.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(daily_trends_url) }
  #     format.xml  { head :ok }
  #   end
  # end
end
