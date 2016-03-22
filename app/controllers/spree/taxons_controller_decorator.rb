Spree::TaxonsController.class_eval do
  include Spree::PageTracker
  track_actions [:show]
end
