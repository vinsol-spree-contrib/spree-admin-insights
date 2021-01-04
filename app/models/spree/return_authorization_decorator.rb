module Spree::ReturnAuthorizationDecorator
  def self.prepend(base)
    base.has_many :variants, through: :inventory_units
    base.has_many :products, through: :variants
  end
end

::Spree::ReturnAuthorization.prepend(Spree::ReturnAuthorizationDecorator)