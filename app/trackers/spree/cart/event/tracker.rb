module Spree
  module Cart
    module Event
      class Tracker < Spree::Event::Tracker
        attr_reader :target
        attr_accessor :activity, :quantity

        def initialize(arguments = {})
          super(arguments)
          @quantity = arguments[:quantity]
          @total = arguments[:total]
          @variant_id = arguments[:variant_id]
        end

        def track
          changed_quantity = changed_quantity(target.previous_changes[:quantity].map(&:to_i))
          self.activity = activity(changed_quantity, target)
          self.quantity = changed_quantity
          CartEvent.create(instance_values)
        end

        private
          # 1. ADD EVENT: When a new product is added to cart
          #    so the changed quantity will be equal to line_item.quantity
          # 2. REMOVE EVENT: When a product is removed from cart,
          #    change in quantity will be negative and line_items quantity will be zero
          # 3. UPDATE EVENT: When product's quantity is changed from the cart and it shouldn't be removed
          def activity(changed_quantity, line_item)
            if (changed_quantity > 0 && changed_quantity == line_item.quantity)
              :add
            elsif (changed_quantity < 0 && line_item.quantity == 0)
              :remove
            elsif changed_quantity
              :update
            end
          end

          def changed_quantity(previous_quantity_changes)
            previous_quantity_changes.last - previous_quantity_changes.first
          end
      end
    end
  end
end
