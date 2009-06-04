class WeeklyTrendsController < ApplicationController
  # GET /weekly_trends
  # GET /weekly_trends.xml
  def index
    @weekly_trends = WeeklyTrend.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @weekly_trends }
    end
  end

  # GET /weekly_trends/1
  # GET /weekly_trends/1.xml
  def show
    @weekly_trend = WeeklyTrend.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @weekly_trend }
    end
  end

  # # GET /weekly_trends/new
  # # GET /weekly_trends/new.xml
  # def new
  #   @weekly_trend = WeeklyTrend.new
  # 
  #   respond_to do |format|
  #     format.html # new.html.erb
  #     format.xml  { render :xml => @weekly_trend }
  #   end
  # end
  # 
  # # GET /weekly_trends/1/edit
  # def edit
  #   @weekly_trend = WeeklyTrend.find(params[:id])
  # end
  # 
  # # POST /weekly_trends
  # # POST /weekly_trends.xml
  # def create
  #   @weekly_trend = WeeklyTrend.new(params[:weekly_trend])
  # 
  #   respond_to do |format|
  #     if @weekly_trend.save
  #       flash[:notice] = 'WeeklyTrend was successfully created.'
  #       format.html { redirect_to(@weekly_trend) }
  #       format.xml  { render :xml => @weekly_trend, :status => :created, :location => @weekly_trend }
  #     else
  #       format.html { render :action => "new" }
  #       format.xml  { render :xml => @weekly_trend.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # # PUT /weekly_trends/1
  # # PUT /weekly_trends/1.xml
  # def update
  #   @weekly_trend = WeeklyTrend.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @weekly_trend.update_attributes(params[:weekly_trend])
  #       flash[:notice] = 'WeeklyTrend was successfully updated.'
  #       format.html { redirect_to(@weekly_trend) }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @weekly_trend.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # # DELETE /weekly_trends/1
  # # DELETE /weekly_trends/1.xml
  # def destroy
  #   @weekly_trend = WeeklyTrend.find(params[:id])
  #   @weekly_trend.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(weekly_trends_url) }
  #     format.xml  { head :ok }
  #   end
  # end
end
