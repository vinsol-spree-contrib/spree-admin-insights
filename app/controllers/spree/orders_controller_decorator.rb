Spree::OrdersController.class_eval do

  include Spree::CheckoutEventTracker

  after_action :track_return_to_cart, only: :edit, if: :current_order
  after_action :track_empty_cart_activity, only: :empty

  private
    def track_empty_cart_activity
      track_activity(activity: :empty_cart, previous_state: previous_state, next_state: nil)
    end

    def track_return_to_cart
      preceeding_state = referred_from_any_checkout_step? ? previous_state : nil
      unless preceeding_state == next_state
        track_activity(activity: activity, previous_state: preceeding_state, next_state: next_state)
      end
    end

    def activity
      !(referred_from_any_checkout_step?) ? :initialize_order : :return_to_cart
    end

    def current_order_includes_previous_state?
      current_order.checkout_steps.include?(previous_state)
    end

    def referred_from_any_checkout_step?
      current_order_includes_previous_state? || previous_state.eql?('cart')
    end

end
