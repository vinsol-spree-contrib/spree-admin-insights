module Spree::PromotionActionDecorator
  def self.prepend(base)
    base.has_one :adjustment, -> { promotion }, class_name: 'Spree::Adjustment', foreign_key: :source_id
  end
end

::Spree::PromotionAction.prepend(Spree::PromotionActionDecorator)