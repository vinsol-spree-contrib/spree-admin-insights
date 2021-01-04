module Spree::ProductDecorator
  def self.prepend(base)
    base.has_many :page_view_events, -> { viewed }, class_name: 'Spree::PageEvent', foreign_key: :target_id
  end
end

::Spree::Product.prepend(Spree::ProductDecorator)