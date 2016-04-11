module Spree
  module CheckoutEventTracker
    extend ActiveSupport::Concern

    def track_activity(attributes)
      default_attributes = {
                             referrer: request.referrer,
                             actor: spree_current_user,
                             target: @order,
                             session_id: session.id
                            }
      Spree::Checkout::Event::Tracker.new(default_attributes.merge(attributes)).track
    end

    def next_state
      @next_state ||= checkout_state(request.url)
    end

    def previous_state
      referrer = request.referrer
      @previous_state ||= (referrer ? checkout_state(referrer) : nil)
    end

    def checkout_state(request_path)
      referrer.split('/').last
    end
  end
end
