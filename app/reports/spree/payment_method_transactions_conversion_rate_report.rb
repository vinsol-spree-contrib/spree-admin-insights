module Spree
  class PaymentMethodTransactionsConversionRateReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :payment_method_name
    HEADERS                    = { payment_method_name: :string, payment_state: :string, month_name: :string, count: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :payments_created_from, end_date: :payments_created_to, name: :payment_method_name }
    SORTABLE_ATTRIBUTES        = [:payment_method_name, :successful_payments_count, :failed_payments_count, :pending_payments_count, :invalid_payments_count]

    class Result < Spree::Report::TimedResult
      charts PaymentMethodStateDistributionChart

      def build_empty_observations
        super
        @_payment_methods = @results.collect { |result| result['payment_method_name'] }.uniq
        @observations = @_payment_methods.collect do |payment_method_name|
          payment_states = @results
                             .select  { |result| result['payment_method_name'] == payment_method_name }
                             .collect { |result| result['payment_state'] }
                             .uniq

          payment_states.collect do |state|
            @observations.collect do |observation|
              _d_observation = observation.dup
              _d_observation.payment_method_name =  payment_method_name
              _d_observation.payment_state = state
              _d_observation.count = 0
              _d_observation
            end
          end
        end.flatten
      end

      class Observation < Spree::Report::TimedObservation
        observation_fields [:payment_method_name, :payment_state, :count]

        def payment_state
          if @payment_state == 'pending'
            @payment_state
          else
            "capturing #{ @payment_state }"
          end
        end

        def describes?(result, time_scale)
          (result['payment_method_name'] == payment_method_name && result['payment_state'] == @payment_state) && super
        end
      end
    end

    def report_query
      Spree::Report::QueryFragments
        .from_subquery(payment_methods)
        .group(*time_scale_columns_to_s, 'payment_method_name', 'payment_state')
        .order(*time_scale_columns)
        .project(
          *time_scale_columns,
          'payment_method_name',
          'payment_state',
          'COUNT(payment_method_id) as count'
        )
    end

    private def payment_methods
      Spree::PaymentMethod
        .joins(:payments)
        .where(spree_payments: { created_at: reporting_period })
        .where(Spree::PaymentMethod.arel_table[:name].matches(search_name))
        .select(
          'spree_payment_methods.id as payment_method_id',
          'name as payment_method_name',
          'state as payment_state',
          *time_scale_selects('spree_payments')
        )
    end
  end
end
