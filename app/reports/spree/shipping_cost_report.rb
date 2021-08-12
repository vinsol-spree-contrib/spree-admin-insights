module Spree
  class ShippingCostReport < Spree::Report
    HEADERS             = { name: :string, shipping_charge: :integer, revenue: :integer, shipping_cost_percentage: :integer }
    SEARCH_ATTRIBUTES   = { start_date: :start_date, end_date: :end_date, name: :name }
    SORTABLE_ATTRIBUTES = []

    class Result < Spree::Report::TimedResult
      charts ShippingCostDistributionChart

      def build_empty_observations
        super
        @_shipping_methods = @results.collect { |r| r['name'] }.uniq
        @observations = @_shipping_methods.collect do |shipping_method|
          @observations.collect do |observation|
            _d_observation                          = observation.dup
            _d_observation.name                     = shipping_method
            _d_observation.revenue                  = 0
            _d_observation.shipping_charge          = 0
            _d_observation.shipping_cost_percentage = 0
            _d_observation
          end
        end.flatten
      end

      class Observation < Spree::Report::TimedObservation
        observation_fields [:name, :shipping_charge, :revenue, :shipping_cost_percentage]

        def describes?(result, time_scale)
          (name == result['name']) && super
        end

        def shipping_cost_percentage
          @revenue.to_f.zero? ? 0 : ((@shipping_charge.to_f * 100) / @revenue.to_f).round(2)
        end
      end
    end

    def report_query
      ar_shipping_methods = Arel::Table.new(:spree_shipping_methods)
      ar_subquery_with_rates = Arel::Table.new(:shipment_with_rates)

      Spree::Report::QueryFragments
        .from_subquery(shipment_with_rates, as: 'shipment_with_rates')
        .join(ar_shipping_methods)
        .where(Spree::ShippingMethod.arel_table[:name].matches(search_name))
        .on(ar_shipping_methods[:id].eq(ar_subquery_with_rates[:shipping_method_id]))
        .project(
          *time_scale_columns,
          ar_shipping_methods[:id],
          'revenue',
          'shipping_charge',
          'shipping_method_id',
          'name'
        ).order('shipping_method_id', *time_scale_columns)
    end

    private def order_with_shipments
      Spree::Order
        .where.not(completed_at: nil)
        .where(completed_at: reporting_period)
        .joins(:shipments)
        .select(
          'spree_shipments.id           as shipment_id',
          'spree_orders.shipment_total  as shipping_charge',
          'spree_orders.id              as order_id',
          'spree_orders.total           as order_total',
          *time_scale_selects_from_column('spree_orders', 'completed_at')
        )
    end

    private def shipment_with_rates
      ar_shipping_rates = Arel::Table.new(:spree_shipping_rates)
      ar_subquery       = Arel::Table.new(:results)

      Spree::Report::QueryFragments.from_subquery(order_with_shipments)
        .join(ar_shipping_rates)
        .on(ar_shipping_rates[:shipment_id].eq(ar_subquery[:shipment_id]))
        .where(ar_shipping_rates[:selected].eq(Arel::Nodes::Quoted.new(true)))
        .group(*time_scale_columns, :shipping_method_id)
        .order(*time_scale_columns)
        .project(
          *time_scale_columns,
          'shipping_method_id',
          'SUM(shipping_charge)  as shipping_charge',
          'SUM(order_total)      as revenue'
        )
    end

  end
end
