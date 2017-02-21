module Spree
  class SalesTaxReport < Spree::Report
    HEADERS = { months_name: :string, zone_name: :string, sales_tax: :integer }
    SEARCH_ATTRIBUTES = { start_date: :taxation_from, end_date: :taxation_till }
    SORTABLE_ATTRIBUTES = []

    def no_pagination?
      true
    end

    def generate(options = {})
      adjustments_with_month_name = SpreeReportify::ReportDb[:spree_adjustments___adjustments].
      join(:spree_tax_rates___tax_rates, id: :source_id).
      join(:spree_zones___zones, id: :zone_id).
      where(adjustments__source_type: "Spree::TaxRate", adjustments__adjustable_type: "Spree::LineItem").
      where(adjustments__created_at: @start_date..@end_date). #filter by params
      select{[
        Sequel.as(abs(adjustments__amount), :sales_tax),
        Sequel.as(:zones__id, :zone_id),
        :zones__name___zone_name,
        Sequel.as(MONTHNAME(:adjustments__created_at), :month_name),
        Sequel.as(YEAR(:adjustments__created_at), :year),
        Sequel.as(MONTH(:adjustments__created_at), :number)
      ]}

      group_by_months = SpreeReportify::ReportDb[adjustments_with_month_name].
      group(:year, :number, :months_name, :zone_id).
      order(:year, :number).
      select{[
        number,
        zone_name,
        year,
        Sequel.as(concat(month_name, ' ', year), :months_name),
        Sequel.as(SUM(sales_tax), :sales_tax)
      ]}
      grouped_by_zone = group_by_months.all.group_by { |record| record[:zone_name] }
      data = []
      grouped_by_zone.each_pair do |zone_name, collection|
        data << fill_missing_values({ sales_tax: 0, zone_name: zone_name }, collection)
      end
      @data = data.flatten
    end

    def group_by_zone_name
      @grouped_by_zone_name ||= @data.group_by { |record| record[:zone_name] }
    end

    def chart_data
      {
        months_name: group_by_zone_name.first.try(:second).try(:map) { |record| record[:months_name] },
        collection: group_by_zone_name
      }
    end

    def chart_json
      {
        chart: true,
        charts: [
          {
            id: 'sale-tax',
            json: {
              chart: { type: 'column' },
              title: {
                useHTML: true,
                text: "<span class='chart-title'>Monthly Sales Tax Comparison</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title='Compare the Sales tax collected from different Zones'></span>"
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
              series: chart_data[:collection].map { |key, value| { type: 'column', name: key, data: value.map { |r| r[:sales_tax].to_f } } }
            }
          }
        ]
      }
    end

    def select_columns(dataset)
      dataset
    end
  end
end
