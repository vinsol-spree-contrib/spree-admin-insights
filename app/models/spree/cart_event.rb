module Spree
  class CartEvent < Spree::Base

    with_options polymorphic: true do
      belongs_to :actor
      belongs_to :target
    end
    belongs_to :variant

    validates :activity,
              :actor,
              :quantity,
              :target,
              :total,
              :variant, presence: true

    scope :events, ->(type) { where(activity: type) }

    delegate :product, to: :variant, allow_blank: true
  end
end
