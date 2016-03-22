module Spree
  module Page
    module Event
      class Tracker < Spree::Event::Tracker
        EVENTS = { show: :view, search: :search, filter: :filter }

        def initialize(arguments = {})
          super(arguments)
          @search_keywords = arguments[:search_keywords]
        end

        def track
          PageEvent.create(instance_values)
        end
      end
    end
  end
end
