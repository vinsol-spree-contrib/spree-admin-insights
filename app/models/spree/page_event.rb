module Spree
  class PageEvent < Spree::Base
    ACTIVITIES = { view: :view, search: :search, filter: :filter }

    with_options polymorphic: true do
      belongs_to :actor
      belongs_to :target
    end

    validates :activity,
              :session_id, presence: true

    scope :product_pages, -> { where(target_type: Spree::Product) }
    scope :activity,      -> (type) { where(activity: type) }
  end
end
