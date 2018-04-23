class Spree::PaymentMethodTransactionsConversionRateReport::PaymentMethodStateDistributionChart
  attr_accessor :chart_data

  def initialize(result)
    @time_dimension = result.time_dimension
    @grouped_by_payment_method = result.observations.group_by(&:payment_method_name)
    @time_series = []
    @time_series = @grouped_by_payment_method.values.first.collect { |observation| observation.send(@time_dimension) } if @grouped_by_payment_method.first.present?
  end

  def to_h
    @grouped_by_payment_method.collect do |method_name, observations|
      {
        id: 'payment-state-' + method_name,
        json: {
          chart: { type: 'column' },
          title: {
            useHTML: true,
            text: %Q(<span class='chart-title'>#{ method_name } Conversion Status</span>
                     <span class='fa fa-question-circle' data-toggle='tooltip' title=' Tracks the status of Payments made from different payment methods such as CC, Check etc.'></span>)
          },

          xAxis: { categories: @time_series },
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
          series: observations.group_by(&:payment_state).map { |key, value| { name: key, data: value.map(&:count).map(&:to_i) } }
        }
      }
    end
  end
end
