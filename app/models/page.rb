class Page < ActiveRecord::Base
  has_one :daily_timeline
  has_one :daily_trend
  has_one :person
  has_one :company
  has_one :weekly_trend    
  named_scope :title_like, lambda { |query| { :conditions => ['title like ? and id NOT IN (?) and featured=0', "#{query}%", APP_CONFIG['blacklist']], :order => '`monthly_trend` DESC', :limit => 14 } }
  named_scope :title_search, lambda { |query| { :conditions => ['title like ?', "#{query}%"], :order => '`total_pageviews` DESC', :limit => 14 } }  
  named_scope :full_title_like, lambda { |query| { :conditions => ['title like ? and id NOT IN (?) and featured=0', "%#{query}%", APP_CONFIG['blacklist']], :order => '`monthly_trend` DESC', :limit => 14 } }  
    
  
  def normed_daily_pageviews( range=30)
    @pageviews = JSON.parse(self.daily_timeline.pageviews)
    @dates = JSON.parse(self.daily_timeline.dates)    
    date_view_hash = {}
    @dates.each_with_index do |date, index|
      date_view_hash[date] = @pageviews[index]
    end
    sorted_pageviews = []
    date_view_hash.keys.sort.each { |key| sorted_pageviews << date_view_hash[key] }
    maxval = sorted_pageviews[-range,range].max
    normed_values = sorted_pageviews[-range,range].collect { |x| x * (110.0 / maxval)}    
    return normed_values
  end
  
  def linechart( fillcolor='76A4FB', range=30 )
    dataset = GC4R::API::GoogleChartDataset.new :data => self.normed_daily_pageviews(range), 
      :color => '999999', :fill => ['B', fillcolor ,'0','0','0']
    # red => FF0000
    # lightblue => 76A4FB
    # green => 33FF00
    # darkblue => 0000FF    
    data = GC4R::API::GoogleChartData.new :datasets => dataset , :min => 0, :max => 120
    # @chart = GoogleBarChart.new :width => 120, :height => 12
    @chart = GC4R::API::GoogleLineChart.new :width => 620, :height => 280
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
      @data[DateTime.strptime( date.to_s, "%Y%m%d")] = {:page_views => pageviews[index]}
    end
    return @data
  end
  
end
