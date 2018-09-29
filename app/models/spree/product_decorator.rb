Spree::Product.class_eval do
  has_many :page_view_events, -> { viewed }, class_name: 'Spree::PageEvent', foreign_key: :target_id
  has_many :archived_page_view_events, -> { viewed }, class_name: 'Spree::ArchivedPageEvent', foreign_key: :target_id
end
