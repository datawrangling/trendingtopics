require 'test/unit'
require 'lib/gc4r'

class GoogleChartsTest < Test::Unit::TestCase
  
# chart  
  # def test_hello_world
  #   chart = GoogleChart.new
  #   assert_equal chart.to_url, "http://chart.apis.google.com/chart?cht=p3&chd=t:60,40&chs=250x100&chl=Hello|World"
  # end
  def test_chart_size
    chart_size = GC4R::ChartSize.new 300, 200
    assert_equal 'chs=300x200', chart_size.create
  end
  def test_bar_chart_with_title
    chart = GC4R::API::GoogleLineChart.new :title => "ura"
    assert_equal "cht=lc&chtt=ura", chart.create
  end
  # def test_chart_with_data
  #   chart = GoogleBarChart.new
  #   chart.data = GoogleChartData.new :datasets => [1,2,3]
  #   assert_equal "cht=bvs&chd=t:1,2,3", chart.create
  # end
  
# chart types
  def test_line_chart
    line_chart = GC4R::API::GoogleLineChart.new
    assert_equal "cht=lc", line_chart.create
    line_chart = GC4R::API::GoogleLineChart.new :chart_type => GC4R::API::GoogleLineChart::XY
    assert_equal "cht=lxy", line_chart.create
  end
  def test_sparkline_chart 
    chart = GC4R::API::GoogleSparklinesChart.new
    assert_equal "cht=ls", chart.create
  end
  def test_bar_chart
    chart = GC4R::API::GoogleBarChart.new
    assert_equal "cht=bvs", chart.create
    chart = GC4R::API::GoogleBarChart.new :chart_type => GC4R::API::GoogleBarChart::HORIZONTAL
    assert_equal "cht=bhs", chart.create
  end
  def test_pie_chart
    chart = GC4R::API::GooglePieChart.new
    assert_equal "cht=p", chart.create
    chart = GC4R::API::GooglePieChart.new :chart_type => GC4R::API::GooglePieChart::PIE_3D
    assert_equal "cht=p3", chart.create
  end
  def test_scatter_plots_chart
    chart = GC4R::API::GoogleScatterPlotsChart.new
    assert_equal "cht=s", chart.create
  end
  
  
# chart data
  def test_chart_data
    chart_data = GC4R::ChartData.new
    assert_equal "chd", chart_data.get_param
    chart_data = GC4R::ChartData.new [1,2,3]
    assert_equal "chd=t:1,2,3", chart_data.create
    chart_data = GC4R::ChartData.new [1,nil,3]
    assert_equal "chd=t:1,-1,3", chart_data.create
    chart_data = GC4R::ChartData.new [[1,2,3],[4,5,6]]
    assert_equal "chd=t:1,2,3|4,5,6", chart_data.create
  end
  def test_chart_data_scale
    chart_data = GC4R::ChartDataScale.new
    assert_equal "chds", chart_data.get_param
    chart_data = GC4R::ChartDataScale.new 1,5
    assert_equal "chds=1,5", chart_data.create
  end
  def test_chart_data_color
    chart_data_color = GC4R::ChartDataColor.new 'red'
    assert_equal 'chco=red', chart_data_color.create
    chart_data_color = GC4R::ChartDataColor.new ['red','blue']
    assert_equal 'chco=red,blue', chart_data_color.create
  end
  def test_chart_legend
    chart_legend = GC4R::ChartDataLegend.new "gdp"
    assert_equal "chdl=gdp", chart_legend.create
    chart_legend = GC4R::ChartDataLegend.new ["gdp"]
    assert_equal "chdl=gdp", chart_legend.create
    chart_legend = GC4R::ChartDataLegend.new ["gdp","ppp"]
    assert_equal "chdl=gdp|ppp", chart_legend.create
  end
  def test_chart_pie_labels
    chart_legend = GC4R::ChartDataPieLabels.new "gdp"
    assert_equal "chl=gdp", chart_legend.create
    chart_legend = GC4R::ChartDataPieLabels.new ["gdp"]
    assert_equal "chl=gdp", chart_legend.create
    chart_legend = GC4R::ChartDataPieLabels.new ["gdp","ppp"]
    assert_equal "chl=gdp|ppp", chart_legend.create
  end
  def test_google_chart_data
    # google_chart_data = GoogleChartData.new
    # assert_equal '', google_chart_data.create
    dataset = GC4R::API::GoogleChartDataset.new :data => [1,2,3,4,5]
    google_chart_data = GC4R::API::GoogleChartData.new :datasets  => dataset
    assert_equal 'chd=t:1,2,3,4,5', google_chart_data.create
    google_chart_data = GC4R::API::GoogleChartData.new :datasets  => dataset, :min => 0, :max => 10
    assert_equal 'chd=t:1,2,3,4,5&chds=0,10', google_chart_data.create
    
    dataset.color = 'red'
    google_chart_data = GC4R::API::GoogleChartData.new :datasets  => dataset
    assert_equal 'chd=t:1,2,3,4,5&chco=red', google_chart_data.create
    
    dataset1 = GC4R::API::GoogleChartDataset.new :data => [1,2,3]
    dataset2 = GC4R::API::GoogleChartDataset.new :data => [4,5]
    google_chart_data = GC4R::API::GoogleChartData.new :datasets  => [ dataset1, dataset2 ]
    assert_equal 'chd=t:1,2,3|4,5', google_chart_data.create
    
    dataset1 = GC4R::API::GoogleChartDataset.new :data => [1,2,3], :color  =>  'red'
    dataset2 = GC4R::API::GoogleChartDataset.new :data => [4,5], :color  =>  'blue'
    google_chart_data = GC4R::API::GoogleChartData.new :datasets  => [ dataset1, dataset2 ]
    assert_equal 'chd=t:1,2,3|4,5&chco=red,blue', google_chart_data.create
    
    dataset1 = GC4R::API::GoogleChartDataset.new :data => [1,2,3], :title => 't1'
    dataset2 = GC4R::API::GoogleChartDataset.new :data => [4,5], :title => 't2'
    google_chart_data = GC4R::API::GoogleChartData.new :datasets  => [ dataset1, dataset2 ]
    assert_equal 'chd=t:1,2,3|4,5&chdl=t1|t2&chl=t1|t2', google_chart_data.create
  end
  
# axis
  def test_chart_axis
    chart_axis = GC4R::ChartAxis.new ["x","y"]
    assert_equal "chxt=x,y", chart_axis.create
  end
  def test_chart_axis_labels
    chart_axis = GC4R::ChartAxisLabels.new ["A","B"]
  end
  def test_google_chart_axis
    google_chart_axis = GC4R::API::GoogleChartAxis.new :axis  => [GC4R::API::GoogleChartAxis::LEFT, GC4R::API::GoogleChartAxis::BOTTOM]
    assert_equal "chxt=y,x", google_chart_axis.create
  end
  
# chart title
  def test_chart_title_size
    chart_title = GC4R::ChartTitleSize.new
    assert_equal 'chts', chart_title.get_param
    chart_title = GC4R::ChartTitleSize.new 'red', 12
    assert_equal 'chts=red,12', chart_title.create
  end
  def test_chart_title_name
    chart_title = GC4R::ChartTitleName.new
    assert_equal 'chtt', chart_title.get_param
    chart_title = GC4R::ChartTitleName.new 'test'
    assert_equal 'chtt=test', chart_title.create
    chart_title = GC4R::ChartTitleName.new ['test', 'title']
    assert_equal 'chtt=test|title', chart_title.create
  end
  def test_chart_title
    chart_title = GC4R::ChartTitle.new :title => 'aaa', :color  => 'red', :fontsize => 10
    assert_equal 'chtt=aaa&chts=red,10', chart_title.create
  end
  
# playground  
  # def test_ruby
  #   chart_title = ChartTitle.new
  #   puts "VARS: #{chart_title.instance_variables}"
  # end
end
