module Spree
  class PageEvent < Spree::Base
    belongs_to :actor, polymorphic: true
    belongs_to :target, polymorphic: true

    validates :referrer, :session_id, :activity, presence: true
  end
end
