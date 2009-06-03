require 'gc4r'

ActionController::Base.class_eval do
  include GC4R::GoogleChartsModule
end
