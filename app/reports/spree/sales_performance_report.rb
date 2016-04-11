module Spree
  class SalesPerformanceReport < Spree::Report
    HEADERS = { months_name: :string, sale_price: :integer, cost_price: :integer, profit_loss: :integer }
    SEARCH_ATTRIBUTES = { start_date: :orders_created_from, end_date: :orders_created_till }
    SORTABLE_ATTRIBUTES = []

    def generate(options = {})
      initialize_months_table
      order_join_line_item = SpreeReportify::ReportDb[:spree_orders___orders].
      exclude(completed_at: nil).
      where(orders__created_at: @start_date..@end_date). #filter by params
      join(:spree_line_items___line_items, order_id: :id).
      group(:line_items__order_id).
      select{[
        Sequel.as(SUM(IFNULL(line_items__cost_price, line_items__price) * line_items__quantity), :cost_price),
        line_items__order_id,
        Sequel.as(orders__item_total, :sale_price),
        Sequel.as(orders__item_total - SUM(IFNULL(line_items__cost_price, line_items__price) * line_items__quantity), :profit_loss),
        Sequel.as(MONTHNAME(:orders__created_at), :month_name),
        Sequel.as(YEAR(:orders__created_at), :year)
      ]}

      group_by_months = SpreeReportify::ReportDb[order_join_line_item].
      right_outer_join(:months, name: :month_name).
      group(:months_name).
      order(:sort_year, :number).
      select{[
        months__number,
        Sequel.as(IFNULL(year, 2016), :sort_year),
        Sequel.as(concat(name, ' ', IFNULL(year, 2016)), :months_name),
        Sequel.as(IFNULL(SUM(sale_price), 0), :sale_price),
        Sequel.as(IFNULL(SUM(cost_price), 0), :cost_price),
        Sequel.as(IFNULL(SUM(profit_loss), 0), :profit_loss)
      ]}
      group_by_months
    end

    def select_columns(dataset)
      dataset
    end

    def chart_json
      {
        chart: true,
        charts: [
          profit_loss_chart_json,
          sale_cost_price_chart_json
        ]
      }
    end

    def chart_data
      @data ||= SpreeReportify::ReportDb[generate].
      select{[
        Sequel.as(group_concat(profit_loss), :profit_loss),
        Sequel.as(group_concat(sale_price), :sale_price),
        Sequel.as(group_concat(cost_price), :cost_price),
        Sequel.as(group_concat(months_name), :months_name)
      ]}.first
    end

    # ---------------------------------------------------- Graph Jsons --------------------------------------------------

    def profit_loss_chart_json
      {
        id: 'profit-loss',
        json: {
          title: { text: 'Profit/Loss' },
          xAxis: { categories: chart_data[:months_name].split(',') },
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
          series: [
            {
              name: 'Profit Loss',
              data: chart_data[:profit_loss].split(',').map(&:to_f)
            }
          ]
        }
      }
    end

    def sale_cost_price_chart_json
      {
        id: 'sale-price',
        json: {
          chart: { type: 'column' },
          title: { text: 'Sale Price' },
          xAxis: { categories: chart_data[:months_name].split(',') },
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
          series: [
            {
              name: 'Sale Price',
              data: chart_data[:sale_price].split(',').map(&:to_f)
            },
            {
              name: 'Cost Price',
              data: chart_data[:cost_price].split(',').map(&:to_f)
            }
          ]
        }
      }
    end
  end
end
