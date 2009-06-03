class DailyTimelinesController < ApplicationController
  # GET /daily_timelines
  # GET /daily_timelines.xml

    
  def index
    @daily_timelines = DailyTimeline.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @daily_timelines }
    end
  end

  # GET /daily_timelines/1
  # GET /daily_timelines/1.xml
  def show
    @daily_timeline = DailyTimeline.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @daily_timeline }
    end
  end

  # GET /daily_timelines/new
  # GET /daily_timelines/new.xml
  def new
    @daily_timeline = DailyTimeline.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @daily_timeline }
    end
  end

  # GET /daily_timelines/1/edit
  def edit
    @daily_timeline = DailyTimeline.find(params[:id])
  end

  # POST /daily_timelines
  # POST /daily_timelines.xml
  def create
    @daily_timeline = DailyTimeline.new(params[:daily_timeline])

    respond_to do |format|
      if @daily_timeline.save
        flash[:notice] = 'DailyTimeline was successfully created.'
        format.html { redirect_to(@daily_timeline) }
        format.xml  { render :xml => @daily_timeline, :status => :created, :location => @daily_timeline }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @daily_timeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /daily_timelines/1
  # PUT /daily_timelines/1.xml
  def update
    @daily_timeline = DailyTimeline.find(params[:id])

    respond_to do |format|
      if @daily_timeline.update_attributes(params[:daily_timeline])
        flash[:notice] = 'DailyTimeline was successfully updated.'
        format.html { redirect_to(@daily_timeline) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @daily_timeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /daily_timelines/1
  # DELETE /daily_timelines/1.xml
  def destroy
    @daily_timeline = DailyTimeline.find(params[:id])
    @daily_timeline.destroy

    respond_to do |format|
      format.html { redirect_to(daily_timelines_url) }
      format.xml  { head :ok }
    end
  end
end
