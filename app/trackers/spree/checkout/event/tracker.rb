module Spree
  module Checkout
    module Event
      class Tracker < Spree::Event::Tracker

        def initialize(arguments = {})
          super(arguments)
          @previous_state = arguments[:previous_state]
          @next_state = arguments[:next_state]
        end

        def track
          CheckoutEvent.create(instance_values)
        end
      end
    end
  end
end
