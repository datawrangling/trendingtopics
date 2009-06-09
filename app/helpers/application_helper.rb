# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  

  def cache_unless( condition, name = {}, options = nil, &block)
          cache_if( !condition, name, options, &block)
  end

  def cache_if( condition, name = {}, options = nil, &block)
          if condition
                  cache(name, options, &block)
          else
                  yield
          end
  end
  
  
end
