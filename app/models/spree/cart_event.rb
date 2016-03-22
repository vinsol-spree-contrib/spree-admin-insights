module Spree
  class CartEvent < Spree::Base
    with_options polymorphic: true do
      belongs_to :actor
      belongs_to :target
    end

    validates :activity,
              :actor,
              :target,
              :quantity,
              :total, presence: true
  end
end
