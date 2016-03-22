Spree::ProductsController.class_eval do
  include Spree::PageTracker
  track_actions [:show, :index]
end
