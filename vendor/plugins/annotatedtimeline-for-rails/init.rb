require File.join(File.dirname(__FILE__), 'lib/annotated_timeline.rb')
ActionView::Base.send(:include, AnnotatedTimeline)