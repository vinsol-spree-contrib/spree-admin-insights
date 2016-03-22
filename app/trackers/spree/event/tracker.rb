module Spree
  module Event
    class Tracker
      def initialize(arguments = {})
        @activity = arguments[:activity]
        @actor = arguments[:actor]
        @target = arguments[:target]
        @referrer = arguments[:referrer]
        @session_id = arguments[:session_id]
      end

      def track
        raise '#track should be implemented in a sub-class of Event::Tracker'
      end
    end
  end
end
