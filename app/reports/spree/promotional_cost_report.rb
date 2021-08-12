module Spree
  class PromotionalCostReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :promotion_name
    HEADERS                    = { promotion_name: :string, usage_count: :integer, promotion_discount: :integer, promotion_code: :string, promotion_start_date: :date, promotion_end_date: :date }
    SEARCH_ATTRIBUTES          = { start_date: :promotion_applied_from, end_date: :promotion_applied_till, name: :promotion_name }
    SORTABLE_ATTRIBUTES        = [:promotion_name, :usage_count, :promotion_discount, :promotion_code, :promotion_start_date, :promotion_end_date]

    class Result < Spree::Report::TimedResult
      charts PromotionalCostChart, UsageCountChart

      def build_empty_observations
        super
        @_promotions = @results.collect { |result| result['promotion_name'] }.uniq
        @observations = @_promotions.collect do |promotion_name|
          @observations.collect do |observation|
            _d_observation = observation.dup
            _d_observation.promotion_name = promotion_name
            _d_observation.usage_count = 0
            _d_observation
          end
        end.flatten
      end

      class Observation < Spree::Report::TimedObservation
        observation_fields [
          :promotion_name, :usage_count,
          :promotion_discount, :promotion_code,
          :promotion_start_date, :promotion_end_date
        ]

        def promotion_start_date
          @promotion_start_date.present? ? @promotion_start_date.to_date.strftime("%B %d %Y") : "-"
        end

        def promotion_end_date
          @promotion_end_date.present? ? @promotion_end_date.to_date.strftime("%B %d %Y") : "-"
        end

        def promotion_discount
          @promotion_discount.to_f.abs
        end

        def describes?(result, time_scale)
          result['promotion_name'] == promotion_name && super
        end
      end
    end

    def report_query
      Spree::Report::QueryFragments
        .from_subquery(eligible_promotions)
        .group(*time_scale_columns, :promotion_id, :promotion_name,
               :promotion_code, :promotion_start_date, :promotion_end_date)
        .order(*time_scale_columns_to_s)
        .project(
          *time_scale_columns,
          'promotion_name',
          'promotion_code',
          'promotion_start_date',
          'promotion_end_date',
          'SUM(promotion_discount)  as promotion_discount',
          'COUNT(promotion_id)      as usage_count',
          'promotion_id'
        )
    end

    private def eligible_promotions
      Spree::PromotionAction
        .joins(:promotion)
        .joins(:adjustment)
        .where(Spree::Promotion.arel_table[:name].matches(search_name))
        .where(spree_adjustments: { created_at: reporting_period })
        .select(
          'spree_promotions.starts_at   as promotion_start_date',
          'spree_promotions.expires_at  as promotion_end_date',
          'spree_adjustments.amount     as promotion_discount',
          'spree_promotions.id          as promotion_id',
          'spree_promotions.name        as promotion_name',
          'spree_promotions.code        as promotion_code',
          *time_scale_selects('spree_adjustments')
        )
    end

  end
end
