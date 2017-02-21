module Spree
  class PaymentMethodTransactionsConversionRateReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :payment_method_name
    HEADERS = { payment_method_name: :string, payment_state: :string, months_name: :string, count: :integer }
    SEARCH_ATTRIBUTES = { start_date: :payments_created_from, end_date: :payments_created_to }
    SORTABLE_ATTRIBUTES = [:payment_method_name, :successful_payments_count, :failed_payments_count, :pending_payments_count, :invalid_payments_count]

    def no_pagination?
      true
    end

    def generate
      payment_methods = SpreeReportify::ReportDb[:spree_payment_methods___payment_methods].
      join(:spree_payments___payments, payment_method_id: :id).
      where(payments__created_at: @start_date..@end_date). #filter by params
      select{[
        payment_method_id,
        Sequel.as(name, :payment_method_name),
        Sequel.as(IF(STRCMP(state, 'pending'), state, concat('capturing ', state)), :payment_state),
        Sequel.as(MONTHNAME(:payments__created_at), :month_name),
        Sequel.as(MONTH(:payments__created_at), :number),
        Sequel.as(YEAR(:payments__created_at), :year)
      ]}

      group_by_months = SpreeReportify::ReportDb[payment_methods].
      group(:year, :number, :months_name, :payment_method_name, :payment_state).
      order(:year, :number).
      select{[
        payment_method_name,
        number,
        payment_state,
        year,
        Sequel.as(concat(month_name, ' ', year), :months_name),
        Sequel.as(COUNT(payment_method_id), :count),
      ]}

      grouped_by_payment_method_name = group_by_months.all.group_by { |record| record[:payment_method_name] }
      data = []
      grouped_by_payment_method_name.each_pair do |name, collection|
        collection.group_by { |r| r[:payment_state] }.each_pair do |state, state_collection|
          data << fill_missing_values({ payment_method_name: name, payment_state: state, count: 0 }, state_collection)
        end
      end
      @data = data.flatten
    end

    def group_by_payment_method_name
      @grouped_by_payment_method_name ||= @data.group_by { |record| record[:payment_method_name] }
    end

    def chart_data
      {
        months_name: group_by_payment_method_name.first.try(:second).try(:map) { |record| record[:months_name] },
        collection: group_by_payment_method_name
      }
    end

    def chart_json
      {
        chart: true,
        charts: chart_data[:collection].map do |method_name, collection|
          {
            id: 'payment-state-' + method_name,
            json: {
              chart: { type: 'column' },
              title: {
                useHTML: true,
                text: "<span class='chart-title'>#{ method_name } Conversion Status</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title=' Tracks the status of Payments made from different payment methods such as CC, Check etc.'></span>"
              },

              xAxis: { categories: chart_data[:months_name] },
              yAxis: {
                title: { text: 'Count' }
              },
              tooltip: { valuePrefix: '#' },
              legend: {
                  layout: 'vertical',
                  align: 'right',
                  verticalAlign: 'middle',
                  borderWidth: 0
              },
              series: collection.group_by { |r| r[:payment_state] }.map { |key, value| { name: key, data: value.map { |r| r[:count].to_i } } }
            }
          }
        end
      }
    end

    def select_columns(dataset)
      dataset
    end
  end
end
