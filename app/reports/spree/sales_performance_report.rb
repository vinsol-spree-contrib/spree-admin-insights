module Spree
  class SalesPerformanceReport < Spree::Report
    HEADERS = { months_name: :string, sale_price: :integer, cost_price: :integer, promotion_discount: :integer, profit_loss: :integer, profit_loss_percent: :integer }
    SEARCH_ATTRIBUTES = { start_date: :orders_created_from, end_date: :orders_created_till }
    SORTABLE_ATTRIBUTES = []

    def no_pagination?
      true
    end

    def generate(options = {})
      order_join_line_item = SpreeReportify::ReportDb[:spree_orders___orders].
      exclude(completed_at: nil).
      where(orders__created_at: @start_date..@end_date). #filter by params
      join(:spree_line_items___line_items, order_id: :id).
      group(:line_items__order_id).
      select{[
        Sequel.as(SUM(IFNULL(line_items__cost_price, line_items__price) * line_items__quantity), :cost_price),
        Sequel.as(orders__item_total, :sale_price),
        Sequel.as(orders__item_total - SUM(IFNULL(line_items__cost_price, line_items__price) * line_items__quantity), :profit_loss),
        Sequel.as(MONTHNAME(:orders__created_at), :month_name),
        Sequel.as(MONTH(:orders__created_at), :number),
        Sequel.as(YEAR(:orders__created_at), :year)
      ]}

      group_by_months = SpreeReportify::ReportDb[order_join_line_item].
      group(:year, :number, :months_name).
      order(:year, :number).
      select{[
        number,
        Sequel.as(IFNULL(year, 2016), :year),
        Sequel.as(concat(month_name, ' ', IFNULL(year, 2016)), :months_name),
        Sequel.as(IFNULL(SUM(sale_price), 0), :sale_price),
        Sequel.as(IFNULL(SUM(cost_price), 0), :cost_price),
        Sequel.as(IFNULL(SUM(profit_loss), 0), :profit_loss),
        Sequel.as((IFNULL(SUM(profit_loss), 0) / SUM(cost_price)) * 100, :profit_loss_percent),
        Sequel.as(0, :promotion_discount)
      ]}

      adjustments_with_month_name = SpreeReportify::ReportDb[:spree_adjustments___adjustments].
      where(adjustments__source_type: "Spree::PromotionAction").
      where(adjustments__created_at: @start_date..@end_date). #filter by params
      select{[
        Sequel.as(abs(:amount), :promotion_discount),
        Sequel.as(MONTHNAME(:adjustments__created_at), :month_name),
        Sequel.as(YEAR(:adjustments__created_at), :year),
        Sequel.as(MONTH(:adjustments__created_at), :number)
      ]}

      promotions_group_by_months = SpreeReportify::ReportDb[adjustments_with_month_name].
      group(:year, :number, :months_name, :sale_price, :cost_price).
      order(:year, :number).
      select{[
        number,
        year,
        Sequel.as(concat(month_name, ' ', year), :months_name),
        Sequel.as(0, :sale_price),
        Sequel.as(0, :cost_price),
        Sequel.as(SUM(promotion_discount) * (-1), :profit_loss),
        Sequel.as(0, :profit_loss_percent),
        Sequel.as(SUM(promotion_discount), :promotion_discount)
      ]}

      union_stats = SpreeReportify::ReportDb[group_by_months.union(promotions_group_by_months)].
      group(:year, :number, :months_name).
      order(:year, :number).
      select{[
        number,
        year,
        months_name,
        Sequel.as(SUM(sale_price), :sale_price),
        Sequel.as(SUM(cost_price), :cost_price),
        Sequel.as(SUM(profit_loss), :profit_loss),
        Sequel.as(ROUND(ABS((SUM(profit_loss) / SUM(cost_price))) * 100, 2), :profit_loss_percent),
        Sequel.as(SUM(promotion_discount), :promotion_discount)
      ]}
      fill_missing_values({ cost_price: 0, sale_price: 0, profit_loss: 0, profit_loss_percent: 0, promotion_discount: 0 }, union_stats.all)
    end

    def select_columns(dataset)
      dataset
    end

    def chart_json
      {
        chart: true,
        charts: [
          profit_loss_chart_json,
          profit_loss_percent_chart_json,
          sale_cost_price_chart_json
        ]
      }
    end

    # extract it in report.rb
    def chart_data
      unless @data
        @data = Hash.new {|h, k| h[k] = [] }
        generate.each do |object|
          object.each_pair do |key, value|
            @data[key].push(value)
          end
        end
      end
      @data
    end

    # ---------------------------------------------------- Graph Jsons --------------------------------------------------

    def profit_loss_chart_json
      {
        id: 'profit-loss',
        json: {
          title: {
            useHTML: true,
            text: "<span class='chart-title'>Profit/Loss</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title='Track the profit or loss value'></span>"
          },
          xAxis: { categories: chart_data[:months_name] },
          yAxis: {
            title: { text: 'Value($)' }
          },
          legend: {
              layout: 'vertical',
              align: 'right',
              verticalAlign: 'middle',
              borderWidth: 0
          },
          series: [
            {
              name: 'Profit Loss',
              tooltip: { valuePrefix: '$' },
              data: chart_data[:profit_loss].map(&:to_f)
            }
          ]
        }
      }
    end

    def profit_loss_percent_chart_json
      {
        id: 'profit-loss',
        json: {
          title: {
            useHTML: true,
            text: "<span class='chart-title'>Profit/Loss %</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title='Track the profit or loss %age to create a projection'></span>"
          },
          xAxis: { categories: chart_data[:months_name] },
          yAxis: {
            title: { text: 'Percentage(%)' }
          },
          legend: {
              layout: 'vertical',
              align: 'right',
              verticalAlign: 'middle',
              borderWidth: 0
          },
          series: [
            {
              name: 'Profit Loss Percent(%)',
              tooltip: { valueSuffix: '%' },
              data: chart_data[:profit_loss_percent].map(&:to_f)
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
          title: {
            useHTML: true,
            text: "<span class='chart-title'>Sales Performance %</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title='Compare the Selling price, cost price and promotional cost over a period of time'></span>"
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
          series: [
            {
              name: 'Sale Price',
              data: chart_data[:sale_price].map(&:to_f)
            },
            {
              name: 'Cost Price',
              data: chart_data[:cost_price].map(&:to_f)
            },
            {
              name: 'Promotional Cost',
              data: chart_data[:promotion_discount].map(&:to_f)
            }
          ]
        }
      }
    end
  end
end
