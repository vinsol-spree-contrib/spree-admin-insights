Spree::Product.class_eval do
  has_many :page_view_events, -> { viewed }, class_name: 'Spree::ArchivedPageEvent', foreign_key: :target_id
end
