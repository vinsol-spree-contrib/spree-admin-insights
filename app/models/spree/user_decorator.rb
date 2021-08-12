module Spree
  module UserDecorator
    def self.prepended(base)
      base.has_many :spree_orders, class_name: 'Spree::Order'
    end
  end
end

if ::Spree::User.included_modules.exclude?(Spree::UserDecorator)
  ::Spree::User.prepend Spree::UserDecorator
end
