class PagesController < ApplicationController
  # GET /pages
  # GET /pages.xml
  protect_from_forgery :only => [:create, :update, :destroy]
  layout 'pages', :except => [:auto_complete_for_search_query]
  #use_google_charts

  def auto_complete_for_search_query
    @pages = Page.title_like params["search"]["query"]
    render :partial => "search_results"
  end  
  
  def index
    @pages = Page.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.xml
  def show
    @page = Page.find(params[:id])

    # @data = {
    #   1.day.ago => { :foo=>123, :bar=>100 },
    #   2.day.ago => { :foo=>345, :bar=>200 },
    #   3.day.ago => { :foo=>445, :bar=>120 }, 
    #   4.day.ago => { :foo=>425, :bar=>140 }, 
    #   5.day.ago => { :foo=>515, :bar=>107 }                    
    # }

    rawdates = JSON.parse(@page.daily_timeline.dates)
    pageviews = JSON.parse(@page.daily_timeline.pageviews)
    
    @data ={}
    rawdates.each_with_index do |date, index|
      @data[DateTime.strptime( date.to_s, "%Y%m%d")] = {:page_views => pageviews[index]}
    end

    puts @data

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.xml
  def new
    @page = Page.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/1/edit
  def edit
    @page = Page.find(params[:id])
  end

  # POST /pages
  # POST /pages.xml
  def create
    @page = Page.new(params[:page])

    respond_to do |format|
      if @page.save
        flash[:notice] = 'Page was successfully created.'
        format.html { redirect_to(@page) }
        format.xml  { render :xml => @page, :status => :created, :location => @page }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.xml
  def update
    @page = Page.find(params[:id])

    respond_to do |format|
      if @page.update_attributes(params[:page])
        flash[:notice] = 'Page was successfully updated.'
        format.html { redirect_to(@page) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.xml
  def destroy
    @page = Page.find(params[:id])
    @page.destroy

    respond_to do |format|
      format.html { redirect_to(pages_url) }
      format.xml  { head :ok }
    end
  end
end
