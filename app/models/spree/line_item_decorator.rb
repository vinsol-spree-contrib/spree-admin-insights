Spree::LineItem.class_eval do
  scope :of_completed_orders, -> { includes(:order).where(spree_orders: { state: :complete }) }
  scope :for_products, ->(product_ids) { includes(:product).where(spree_products: { id: product_ids }) }

  delegate :user, to: :order, allow_nil: true
end
