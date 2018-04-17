Spree::AppConfiguration.class_eval do
  preference :records_per_page, :integer, default: 20
end
