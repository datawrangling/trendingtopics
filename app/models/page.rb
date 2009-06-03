class Page < ActiveRecord::Base
  has_one :daily_timeline
  named_scope :title_like, lambda { |query| { :conditions => ['title like ?', "#{query}%"], :order => '`total_pageviews` DESC', :limit => 20 } }

  
  def normed_daily_pageviews
    @pageviews = JSON.parse(self.daily_timeline.pageviews)
    @dates = JSON.parse(self.daily_timeline.dates)    
    maxval = @pageviews.max
    normed_values = @pageviews.collect { |x| x * (120.0 / maxval)}
    date_view_hash = {}
    @dates.each_with_index do |date, index|
      date_view_hash[date] = normed_values[index]
    end
    sorted_pageviews = []
    date_view_hash.keys.sort.each { |key| sorted_pageviews << date_view_hash[key] }
    return sorted_pageviews
  end
  
  def chart
    # todo: move the data fetching out to the model
    # prepare some nice charts here 
    # dataset = GC4R::API::GoogleChartDataset.new :data => (1..30).map{ rand(100) }, :color => '0000FF'   

    dataset = GC4R::API::GoogleChartDataset.new :data => self.normed_daily_pageviews, :color => '0000FF'
    data = GC4R::API::GoogleChartData.new :datasets => dataset , :min => 0, :max => 120
    # @chart = GoogleBarChart.new :width => 120, :height => 12
    @chart = GC4R::API::GoogleSparklinesChart.new :width => 120, :height => 12
    @chart.data = data
    return @chart
  end  
  
end
