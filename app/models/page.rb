class Page < ActiveRecord::Base
  has_one :daily_timeline
  has_one :person
  has_one :company  
  named_scope :title_like, lambda { |query| { :conditions => ['title like ? and featured=0', "#{query}%"], :order => '`monthly_trend` DESC', :limit => 12 } }
  named_scope :title_search, lambda { |query| { :conditions => ['title like ?', "#{query}%"], :order => 'monthly_trend DESC', :limit => 14 } }  
  named_scope :full_title_like, lambda { |query| { :conditions => ['title like ? and id NOT IN (?) and featured=0', "%#{query}%", APP_CONFIG['blacklist']], :order => '`monthly_trend` DESC', :limit => 14 } }  
  
  # for images in "people" trends, optional
  BOSSMan.application_id = APP_CONFIG['yahoo_boss_id']
  
  def to_param
    "#{url}"
  end
  
  def daily_embed_code
    '<!-- TREND CHART --><div style="width: 620px;" class="chart"><script src="http://www.trendingtopics.org/widgets/daily_chart_widget/'+ self.id.to_s + '.js?range=60"></script></div><!-- END TREND CHART -->'
  end
  
  
  def normed_daily_pageviews( range=30, labels=false)
    # produces data scaled for google charts
    @pageviews = JSON.parse(self.daily_timeline.pageviews)
    @dates = JSON.parse(self.daily_timeline.dates)    
    date_view_hash = {}
    @dates.each_with_index do |date, index|
      date_view_hash[date] = @pageviews[index]
    end
    sorted_pageviews = []
    date_view_hash.keys.sort.each { |key| sorted_pageviews << date_view_hash[key] }
    maxval = sorted_pageviews[-(range+1),range].max
    normed_values = sorted_pageviews[-(range+1),range].collect { |x| x * (110.0 / maxval)} 
    unless labels
      return normed_values
    end
    # return 6 date labels over range ( Apr 15, Apr 30, etc.)
    # return 5 pageview values (0, .20, .40, .60, .80, max)   
    # datelabels = '0:|Jan|Feb|Mar|Apr|'
    # valuelabels = '1:|0k|1k|2k|3k|' 
    ticks = [0.2, 0.4, 0.6, 0.8, 1.0]  
    sorted_dates = date_view_hash.keys.sort[-(range+1),range]
    @dateticks=[DateTime.strptime(sorted_dates[0].to_s, "%Y%m%d").strftime("%b %d")]
    ticks.each_with_index do |tick, index|  
      @dateticks << DateTime.strptime(sorted_dates[range*tick -1].to_s, "%Y%m%d").strftime("%b %d")    
    end 
    if maxval >= 1000
      yval = (maxval/1000).round.to_s + 'k'
    else
      yval = (maxval - (maxval%50) + 100).to_s
    end
    axislabels =  "0:|"+ @dateticks.join("|") + "|1:|0|#{yval}|"
    return axislabels, normed_values
  end
  
  def linechart( fillcolor='76A4FB', range=30, chart_title="" )
    # # labels should be 0, maxval*.25, maxval*.75, maxval
    # expressed in thousands (k), or millions (m) if needed
    #labels = labels
    axislabels, normed_values = self.normed_daily_pageviews(range, labels=true)
    dataset = GC4R::API::GoogleChartDataset.new :data => normed_values, 
      :color => 'FF0000'#, :fill => ['B', fillcolor ,'0','0','0']
    # red => FF0000
    # lightblue => 76A4FB
    # green => 33FF00
    # darkblue => 0000FF    
    data = GC4R::API::GoogleChartData.new :datasets => dataset , :min => 0, :max => 120
    # @chart = GoogleBarChart.new :width => 120, :height => 12
    axis = GC4R::API::GoogleChartAxis.new :axis  => [GC4R::API::GoogleChartAxis::BOTTOM, GC4R::API::GoogleChartAxis::LEFT,GC4R::API::GoogleChartAxis::BOTTOM], :labels => axislabels +'2:| | |Powered by trendingtopics.org|'
    #'0:|Jan|Feb|Mar|Apr|1:|0k|1k|2k|3k|2:| | |Powered by trendingtopics.org|'
    @chart = GC4R::API::GoogleLineChart.new :width => 620, :height => 280, :title => chart_title
    @chart.axis = axis
    @chart.data = data
    return @chart
  end  
  
  def sparkline( fillcolor='76A4FB', range=30 )
    dataset = GC4R::API::GoogleChartDataset.new :data => self.normed_daily_pageviews(range), 
      :color => '999999', :fill => ['B', fillcolor ,'0','0','0']
    # red => FF0000
    # lightblue => 76A4FB
    # green => 33FF00
    # darkblue => 0000FF    
    data = GC4R::API::GoogleChartData.new :datasets => dataset , :min => 0, :max => 120
    # @chart = GoogleBarChart.new :width => 120, :height => 12
    @chart = GC4R::API::GoogleSparklinesChart.new :width => 120, :height => 15
    @chart.data = data
    return @chart
  end  
  
  def snippet_title
    @newsboss = BOSSMan::Search.news(self.title, { :filter => "-porn"}) || @newsboss
    if @newsboss.totalhits.to_i > 0
      result = @newsboss.results[0]      
      @title = result.title      # Title of news story
    else   
      @title = "..."  
    end  
  end  
  
  def snippet_url
    @newsboss = BOSSMan::Search.news(self.title, { :filter => "-porn"}) || @newsboss
    if @newsboss.totalhits.to_i > 0
      result = @newsboss.results[0]      
      @clickurl = result.clickurl  # url of lead news story
    else   
      @clickurl = self.url
    end  
  end  
  
  
  def news_snippet
    @newsboss = BOSSMan::Search.news(self.title, { :filter => "-porn"}) || @newsboss
    if @newsboss.totalhits.to_i > 0
      result = @newsboss.results[0]         
      @abstract = result.abstract    # Description of news story 
    else   
      @abstract = '...'  
    end  
  end  
  
  
  
  def picture
    boss = BOSSMan::Search.images(self.title, { :filter => "-porn"})
    if boss.totalhits.to_i > 0
      result = boss.results[0]
      url = result.thumbnail_url      
    else   
      url = "White_square_with_question_mark.png"  
    end  
  end  
  
  def picture_size(desired_height)
    boss = BOSSMan::Search.images(self.title, { :filter => "-porn"})
    if boss.totalhits.to_i > 0
      result = boss.results[0]
      height = result.thumbnail_height.to_i
      width = result.thumbnail_width.to_i
      width_scale_factor = 1.0*desired_height/height
      new_width = width_scale_factor*width
      "#{new_width.to_i}x#{desired_height.to_i}"      
    else
      height = 120
      width = 120
      width_scale_factor = 1.0*desired_height/height
      new_width = width_scale_factor*width
      "#{new_width.to_i}x#{desired_height.to_i}"        
    end  
  end      
  
  
  def sorted_dates
    rawdates = JSON.parse(self.daily_timeline.dates)
    @data = []
    rawdates.each do |date|
      @data << DateTime.strptime( date.to_s, "%Y%m%d")
    end
    @data.sort
  end  
  
  def date_pageview_array
    rawdates = JSON.parse(self.daily_timeline.dates)
    pageviews = JSON.parse(self.daily_timeline.pageviews)    
    @data = []
    rawdates.each_with_index do |date, index|
      @data << [DateTime.strptime( date.to_s, "%Y%m%d").strftime('%D'), pageviews[index]]
    end
    return @data
  end
  
  
  def timeline
    rawdates = JSON.parse(self.daily_timeline.dates)
    pageviews = JSON.parse(self.daily_timeline.pageviews)
        
    @data ={}
    rawdates.each_with_index do |date, index|
      @data[DateTime.strptime( date.to_s, "%Y%m%d")] = {:wikipedia_page_views => pageviews[index]}
    end
    return @data
  end
  
end
