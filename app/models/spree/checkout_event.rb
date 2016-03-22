module Spree
  class CheckoutEvent < Spree::Base

    with_options polymorphic: true do
      belongs_to :actor
      belongs_to :target
    end

    validates :target, :session_id, :activity, presence: true

  end
end
