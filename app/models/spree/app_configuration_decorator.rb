module Spree::AppConfigurationDecorator
  def self.prepend(base)
    base.preference :records_per_page, :integer, default: 20
  end
end

::Spree::AppConfiguration.prepend(Spree::AppConfigurationDecorator)