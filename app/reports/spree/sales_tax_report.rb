module Spree
  class SalesTaxReport < Spree::Report
    HEADERS             = { zone_name: :string, sales_tax: :integer }
    SEARCH_ATTRIBUTES   = { start_date: :taxation_from, end_date: :taxation_till, name: :zone_name }
    SORTABLE_ATTRIBUTES = []

    class Result < Spree::Report::TimedResult
      charts MonthlySalesTaxComparisonChart

      def build_empty_observations
        super
        @_zones = @results.collect { |r| r['zone_name'] }.uniq
        @observations = @_zones.collect do |zone|
          @observations.collect do |observation|
            _d_observation = observation.dup
            _d_observation.zone_name = zone
            _d_observation.sales_tax = 0
            _d_observation
          end
        end.flatten
      end

      class Observation < Spree::Report::TimedObservation
        observation_fields [:zone_name, :sales_tax]

        def describes?(result, time_scale)
          (zone_name == result['zone_name']) && super
        end

        def sales_tax
          @sales_tax.to_f
        end
      end
    end

    def report_query
      Spree::Report::QueryFragments
        .from_subquery(tax_adjustments)
        .group(*time_scale_columns_to_s, 'zone_name')
        .order(*time_scale_columns)
        .project(
          'zone_name',
          *time_scale_columns,
          'SUM(sales_tax) as sales_tax'
        )
    end

    private def tax_adjustments
      Spree::TaxRate
        .joins(adjustments: :order)
        .joins(:zone)
        .where(spree_adjustments: { adjustable_type: 'Spree::LineItem' } )
        .where(spree_orders: { completed_at: reporting_period })
        .where(Spree::Zone.arel_table[:name].matches(search_name))
        .select(
          'spree_adjustments.amount  as sales_tax',
          'spree_zones.id            as zone_id',
          'spree_zones.name          as zone_name',
          *time_scale_selects('spree_adjustments')
        )
    end

  end
end
