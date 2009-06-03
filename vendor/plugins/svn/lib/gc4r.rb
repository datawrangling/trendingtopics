module GC4R
  
  module GoogleChartsModule #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end
    module ClassMethods
      def use_google_charts
        include GC4R::API
      end
    end
  end # GoogleCharts
  

  module GoogleChartsObject #:nodoc:
    def create
      get_param + '=' + get_value
    end
    def get_param
    end
    def get_value
    end
    def valid?
    end
    def expand_multiple data, delimiter = "|"
      if data.is_a?(Array)
        data.join delimiter
      else
        data
      end
    end
    def validates value
      !value.nil?
    end
  end
  module GoogleChartContainer
    def create
      uri = []
      @params.each do |param|
        if param.valid?
          uri << param.create
        end
      end
      uri.join "&"
    end
    def add(param)
      @params ||= []
      @params << param
    end
    def valid? # if at least on child is valid
      valid = false;
      @params.each do |param|
        valid ||= param.valid?
      end
      valid
    end
  end
  class ChartContainer
    include GoogleChartContainer
  end

# objects  
  class Chart < Struct.new :chart_type
    include GoogleChartsObject
    def get_param
      'cht'
    end
    def get_value
      chart_type
    end
    def valid?
      validates chart_type
    end
  end
  class ChartSize < Struct.new :width, :height
    include GoogleChartsObject
    def get_param
      'chs'
    end
    def get_value
      width.to_s + 'x' + height.to_s
    end
    def valid?
      !width.nil? and !height.nil?
    end
  end

  # data
  class ChartData < Struct.new :datasets, :min, :max
    include GoogleChartsObject
    def get_param
      'chd'
    end
    def get_value
      if datasets[0].is_a?(Array)
        't:' + datasets.map{ |value| mangle(value).join(",") }.join("|")
      else
        't:' + mangle(datasets).join(",")
      end
    end
    def valid?
      !datasets.nil? && !datasets.empty?
    end
  private
    def mangle dataset
      dataset.map do |value| 
        if value.nil?
          -1
        else
          value
        end
      end
    end
  end
  class ChartDataScale < Struct.new :min, :max
    include GoogleChartsObject
    def get_param
      "chds"
    end
    def get_value
      min.to_s + ',' + max.to_s
    end
    def valid?
      !min.nil? && !max.nil?
    end
  end
  class ChartDataColor < Struct.new :colors
    include GoogleChartsObject
    def get_param
      "chco"
    end
    def get_value
      expand_multiple colors, ","
    end
    def valid?
      !colors.nil? && !colors.empty?
    end
  end
  class ChartDataLegend < Struct.new :names
    include GoogleChartsObject
    def get_param
      'chdl'
    end
    def get_value
      expand_multiple names
    end
    def valid?
      # TODO hack 
      !names.nil? && !names.empty?
    end
  end
  class ChartDataPieLabels < Struct.new :names #TODO hack, hack hack 
    include GoogleChartsObject
    def get_param
      'chl'
    end
    def get_value
      expand_multiple names
    end
    def valid?
      # TODO hack 
      !names.nil? && !names.empty?
    end
  end
  class ChartAxis < Struct.new :axis
    include GoogleChartsObject
    def get_param
      'chxt'
    end
    def get_value
      expand_multiple axis, ","
    end
    def valid?
      validates axis
    end
  end
  class ChartAxisLabels < Struct.new :labels
    include GoogleChartsObject
    def get_param
      'chxl'
    end
    def get_value
      labels
    end
    def valid?
      validates labels
    end
  end
  # title
  class ChartTitleSize < Struct.new :color, :fontsize
    include GoogleChartsObject
    def get_param
      'chts'
    end
    def get_value
      color + ',' + fontsize.to_s
    end
    def valid?
      !color.nil? and !fontsize.nil?
    end
  end
  class ChartTitleName < Struct.new :title
    include GoogleChartsObject
    def get_param
      'chtt'
    end
    def get_value
      expand_multiple title
    end
    def valid?
      validates title
    end
  end
  class ChartTitle < ChartContainer
    def initialize options = {}
      add ChartTitleName.new(options[:title])
      add ChartTitleSize.new(options[:color], options[:fontsize])
    end
  end
 
#
# GC4R exported API 
#
  module API #:nodoc:
    # base chart
    class GoogleChart < GC4R::ChartContainer
      GOOGLE_CHART_URL = 'http://chart.apis.google.com/chart?'
      HELLO_WORLD = "cht=p3&chd=t:60,40&chs=250x100&chl=Hello|World"
      def initialize options={}
        add Chart.new(options[:chart_type])
        add ChartTitle.new(options)
        add ChartSize.new(options[:width], options[:height])
      end
      def to_url
        uri = create
        if uri.nil? || uri.empty?
          uri = HELLO_WORLD
        end
        url = GOOGLE_CHART_URL + uri
        puts "Google Chart: #{url}" 
        url
      end
      def data=(d)
        add d
      end
      def axis=(a)
        add a
      end
    end
    
    # chart types
    class GoogleLineChart < GoogleChart
      SIMPLE = 'lc'
      XY = 'lxy'
      def initialize options={}
        options[:chart_type] ||= SIMPLE
        super
      end
    end
    class GoogleSparklinesChart < GoogleChart
      def initialize options = {}
        options[:chart_type] = "ls"
        super
      end
    end
    class GoogleBarChart < GoogleChart
      VERTICAL = 'bvs'
      HORIZONTAL = 'bhs'
      def initialize options = {}
        options[:chart_type] ||= VERTICAL
        super
      end
    end
    class GooglePieChart < GoogleChart
      PIE_2D = 'p'
      PIE_3D = 'p3'
      def initialize options = {}
        options[:chart_type] ||= PIE_2D
        super
      end
    end
    class GoogleScatterPlotsChart < GoogleChart
      def initialize options = {}
        options[:chart_type] = "s"
        super
      end
    end
    
    # data and dataset
    class GoogleChartDataset 
      attr_accessor :data, :color, :title
      def initialize options={}
        @data = options[:data]
        @color = options[:color]
        @title = options[:title]
      end
    end
    class GoogleChartData < ChartContainer
      def initialize options = {}
        datasets = [] 
        colors = []
        legend = []
        if options[:datasets].is_a?(Array)
          options[:datasets].each do |dataset|
            datasets << dataset.data
            colors << dataset.color
            legend << dataset.title
          end
        else
          datasets << options[:datasets].data
          colors << options[:datasets].color
          legend << options[:datasets].title
        end
        add ChartData.new(datasets.compact)
        add ChartDataColor.new(colors.compact)
        add ChartDataLegend.new(legend.compact)
        add ChartDataPieLabels.new(legend.compact)
        add ChartDataScale.new(options[:min], options[:max])
      end
    end
    # axis
    class GoogleChartAxis < ChartContainer
      LEFT = 'y'
      BOTTOM = 'x'
      RIGHT = 'r'
      TOP = 't'
      def initialize options={}
        add ChartAxis.new options[:axis]
      end
    end
  end

  
end

