module Spree::ReturnAuthorizationDecorator
  def self.prepend(base)
    has_many :variants, through: :inventory_units
    has_many :products, through: :variants
  end
end

::Spree::ReturnAuthorization.prepend(Spree::ReturnAuthorizationDecorator)