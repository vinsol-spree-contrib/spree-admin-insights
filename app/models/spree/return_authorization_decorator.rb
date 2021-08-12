module Spree
  module ReturnAuthorizationDecorator
    def self.prepended(base)
      base.has_many :variants, through: :inventory_units
      base.has_many :products, through: :variants
    end
  end
end

if ::Spree::ReturnAuthorization.included_modules.exclude?(Spree::ReturnAuthorizationDecorator)
  ::Spree::ReturnAuthorization.prepend Spree::ReturnAuthorizationDecorator
end

