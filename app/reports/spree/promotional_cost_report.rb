module Spree
  class PromotionalCostReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :promotion_name
    HEADERS = { promotion_name: :string, usage_count: :integer, promotion_discount: :integer, promotion_code: :string, promotion_start_date: :date, promotion_end_date: :date }
    SEARCH_ATTRIBUTES = { start_date: :promotion_created_from, end_date: :promotion_created_till }
    SORTABLE_ATTRIBUTES = [:promotion_name, :usage_count, :promotion_discount, :promotion_code, :promotion_start_date, :promotion_end_date]

    def no_pagination?
      true
    end

    def initialize(options)
      super
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate(options = {})
      adjustments_with_month_name = SpreeReportify::ReportDb[:spree_adjustments___adjustments].
      join(:spree_promotion_actions___promotion_actions, id: :source_id).
      join(:spree_promotions___promotions, id: :promotion_id).
      where(adjustments__source_type: "Spree::PromotionAction").
      where(adjustments__created_at: @start_date..@end_date). #filter by params
      select{[
        Sequel.as(abs(:amount), :promotion_discount),
        Sequel.as(:promotions__id, :promotions_id),
        :promotions__name___promotion_name,
        :promotions__code___promotion_code,
        Sequel.as(DATE_FORMAT(promotions__starts_at,'%d %b %y'), :promotion_start_date),
        Sequel.as(DATE_FORMAT(promotions__expires_at,'%d %b %y'), :promotion_end_date),
        Sequel.as(MONTHNAME(:adjustments__created_at), :month_name),
        Sequel.as(YEAR(:adjustments__created_at), :year),
        Sequel.as(MONTH(:adjustments__created_at), :number)
      ]}

      group_by_months = SpreeReportify::ReportDb[adjustments_with_month_name].
      group(:year, :number, :months_name, :promotions_id).
      order(:year, :number).
      select{[
        number,
        promotion_name,
        year,
        promotion_code,
        promotion_start_date,
        promotion_end_date,
        Sequel.as(concat(month_name, ' ', year), :months_name),
        Sequel.as(SUM(promotion_discount), :promotion_discount),
        Sequel.as(count(:promotions_id), :usage_count),
        promotions_id
      ]}
      grouped_by_promotion = group_by_months.all.group_by { |record| record[:promotion_name] }
      data = []
      grouped_by_promotion.each_pair do |promotion_name, collection|
        data << fill_missing_values({ promotion_discount: 0, usage_count: 0, promotion_name: promotion_name }, collection)
      end
      @data = data.flatten
    end

    def group_by_promotion_name
      @grouped_by_promotion_name ||= @data.group_by { |record| record[:promotion_name] }
    end

    def chart_data
      {
        months_name: group_by_promotion_name.first.try(:second).try(:map) { |record| record[:months_name] },
        collection: group_by_promotion_name
      }
    end

    def chart_json
      {
        chart: true,
        charts: [
          promotional_cost_chart_json,
          usage_count_chart_json
        ]
      }
    end

    def promotional_cost_chart_json
      {
        id: 'promotional-cost',
        json: {
          chart: { type: 'column' },
          title: {
            useHTML: true,
            text: "<span class='chart-title'>Promotional Cost</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title=' Compare the costing for various promotions'></span>"
          },
          xAxis: { categories: chart_data[:months_name] },
          yAxis: {
            title: { text: 'Value($)' }
          },
          tooltip: { valuePrefix: '$' },
          legend: {
              layout: 'vertical',
              align: 'right',
              verticalAlign: 'middle',
              borderWidth: 0
          },
          series: chart_data[:collection].map { |key, value| { type: 'column', name: key, data: value.map { |r| r[:promotion_discount].to_f } } }
        }
      }
    end

    def usage_count_chart_json
      {
        id: 'promotion-usage-count',
        json: {
          chart: { type: 'spline' },
          title: {
            useHTML: true,
            text: "<span class='chart-title'>Promotion Usage Count</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title='Compare the usage of individual promotions'></span>"
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
          series: chart_data[:collection].map { |key, value| { name: key, data: value.map { |r| r[:usage_count].to_i } } }
        }
      }
    end

    def select_columns(dataset)
      dataset
    end
  end
end
