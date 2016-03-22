module Spree
  class PageEvent < Spree::Base

    with_options polymorphic: true do
      belongs_to :actor
      belongs_to :target
    end

    validates :activity,
              :referrer,
              :session_id, presence: true

  end
end
