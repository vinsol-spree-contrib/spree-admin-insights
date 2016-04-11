Spree::Adjustment.class_eval do
  delegate :promotion, to: :source, allow_nil: true
end
