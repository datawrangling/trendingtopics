class Page < ActiveRecord::Base
  has_one :daily_timeline
  has_one :daily_trend
  has_one :weekly_trend    
  named_scope :title_like, lambda { |query| { :conditions => ['title like ?', "#{query}%"], :order => '`monthly_trend` DESC', :limit => 12 } }
  named_scope :full_title_like, lambda { |query| { :conditions => ['title like ?', "%#{query}%"], :order => '`monthly_trend` DESC', :limit => 12 } }  
  
  # def to_param
  #   "#{url}"
  # end
  # 
  # 
  
  def normed_daily_pageviews
    @pageviews = JSON.parse(self.daily_timeline.pageviews)
    @dates = JSON.parse(self.daily_timeline.dates)    
    maxval = @pageviews.max
    normed_values = @pageviews.collect { |x| x * (110.0 / maxval)}
    date_view_hash = {}
    @dates.each_with_index do |date, index|
      date_view_hash[date] = normed_values[index]
    end
    sorted_pageviews = []
    date_view_hash.keys.sort.each { |key| sorted_pageviews << date_view_hash[key] }
    return sorted_pageviews[-30,30]
  end
  
  def sparkline( fillcolor='76A4FB' )
    dataset = GC4R::API::GoogleChartDataset.new :data => self.normed_daily_pageviews, 
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
