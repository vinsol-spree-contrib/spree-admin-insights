module Spree
  module PromotionActionDecorator
    def self.prepended(base)
      base.has_one :adjustment, -> { promotion }, class_name: 'Spree::Adjustment', foreign_key: :source_id
    end
  end
end

if ::Spree::PromotionAction.included_modules.exclude?(Spree::PromotionActionDecorator)
  ::Spree::PromotionAction.prepend Spree::PromotionActionDecorator
end
