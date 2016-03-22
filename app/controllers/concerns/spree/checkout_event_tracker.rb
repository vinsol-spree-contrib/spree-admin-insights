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
      @next_state ||= request.url.split('/').last
    end

    def previous_state
      @previous_state ||= (request.referrer ? request.referrer.split('/').last : nil)
    end

  end
end
