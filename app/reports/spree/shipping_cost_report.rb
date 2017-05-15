module Spree
  class ShippingCostReport < Spree::Report
    HEADERS = { months_name: :string, name: :string, shipping_charge: :integer, revenue: :integer, shipping_cost_percentage: :integer }
    SEARCH_ATTRIBUTES = { start_date: :start_date, end_date: :end_date }
    SORTABLE_ATTRIBUTES = []

    def no_pagination?
      true
    end

    def generate(options = {})
      order_join_shipments = SpreeAdminInsights::ReportDb[:spree_orders___orders].
        exclude(completed_at: nil).
        join(:spree_shipments___shipments, order_id: :id).
        where(orders__created_at: @start_date..@end_date).#filter by params
      select { [
        Sequel.as(shipments__id, :shipment_id),
        Sequel.as(orders__shipment_total, :shipping_charge),
        Sequel.as(shipments__order_id, :order_id),
        Sequel.as(orders__total, :order_total),
        Sequel.as(DBUtils.month_name(:orders__created_at), :month_name),
        Sequel.as(DBUtils.month_number(:orders__created_at), :number),
        Sequel.as(DBUtils.year(:orders__created_at), :year)
      ] }.as(:order_shipment)

      order_shipment_rates = SpreeAdminInsights::ReportDb[order_join_shipments].
        join(:spree_shipping_rates___shipping_rates, shipment_id: :order_shipment__shipment_id).
        where(selected: true).
        select { [
        order_id,
        shipping_charge,
        order_total,
        shipping_method_id,
        month_name,
        number,
        year,
        Sequel.as(concat(month_name, ' ', COALESCE(year, '2016')), :months_name),
      ] }.as(:order_shipment_rates)

      revenue_table = SpreeAdminInsights::ReportDb[order_shipment_rates].
        group(:order_shipment_rates__month_name, :order_shipment_rates__year).
        select { [
        Sequel.as(concat(month_name, ' ', COALESCE(year, '2016')), :months_name),
        Sequel.as(SUM(order_total), :revenue)
      ] }.as(:revenue_table)

      grouped_by_method_name = grouped_by_months(order_shipment_rates, revenue_table).all.group_by do |record|
        record[:name]
      end

      data = []
      grouped_by_method_name.each_pair do |name, collection|
        data << fill_missing_values({ shipping_charge: 0, revenue: 0, name: name, shipping_cost_percentage: 0 }, collection)
      end
      @data = data.flatten
    end

    def group_by_method_name
      @grouped_by_method_name ||= @data.group_by { |record| record[:name] }
    end

    def chart_data
      {
        months_name: group_by_method_name.first.try(:second).try(:map) { |record| record[:months_name] },
        collection: group_by_method_name
      }
    end

    def chart_json
      {
        chart: true,
        charts: [
          {
            id: 'shipping-cost-percentage-comparison',
            json: {
              chart: { type: 'spline' },
              title: {
                useHTML: true,
                text: "<span class='chart-title'>Monthly Shipping Comparison</span><span class='glyphicon glyphicon-question-sign' data-toggle='tooltip' title='Compare the Shipping percentage (calculated on Revenue) among various shipment methods such as UPS, FedEx etc.'></span>"
              },
              xAxis: { categories: chart_data[:months_name] },
              yAxis: {
                title: { text: 'Percentage(%)' }
              },
              tooltip: { valueSuffix: '%' },
              legend: {
                layout: 'vertical',
                align: 'right',
                verticalAlign: 'middle',
                borderWidth: 0
              },
              series: chart_data[:collection].map { |key, value| { name: key, data: value.map { |r| r[:shipping_cost_percentage].to_f } } }
            }
          }
        ]
      }
    end

    def select_columns(dataset)
      dataset
    end

    private

    def grouped_by_months(order_shipment_rates, revenue_table)
      case DBUtils.adapter
        when :postgresql
          grouped_by_months_postgresql(order_shipment_rates, revenue_table)
        else
          grouped_by_months_mysql(order_shipment_rates, revenue_table)
      end
    end

    def grouped_by_months_postgresql(order_shipment_rates, revenue_table)
      shipping_charge_table = SpreeAdminInsights::ReportDb[order_shipment_rates]
                                .group(:revenue_table__months_name, :spree_shipping_methods__id)
                                .join(:spree_shipping_methods, id: :order_shipment_rates__shipping_method_id)
                                .join(revenue_table, months_name: :order_shipment_rates__months_name)
                                .select { [
        Sequel.as(SUM(:shipping_charge), :shipping_charge),
        :revenue_table__months_name,
        :spree_shipping_methods__id
      ] }.as(:shipping_charge_table)

      unordered_group_by_months = SpreeAdminInsights::ReportDb[order_shipment_rates]
                                    .join(:spree_shipping_methods, id: :order_shipment_rates__shipping_method_id)
                                    .join(shipping_charge_table, months_name: :order_shipment_rates__months_name)
                                    .join(revenue_table, months_name: :order_shipment_rates__months_name)
                                    .distinct(:order_shipment_rates__months_name, :spree_shipping_methods__id)
                                    .select { [
        :order_shipment_rates__order_id,
        :spree_shipping_methods__id,
        :shipping_charge_table__shipping_charge,
        :revenue_table__revenue,
        :shipping_method_id,
        Sequel.as(concat(month_name, ' ', COALESCE(year, '2016')), :months_name),
        Sequel.as(
          Sequel.lit("ROUND((shipping_charge_table.shipping_charge / revenue_table.revenue :: NUMERIC) * 100, 2)"),
          :shipping_cost_percentage
        ),
        :number,
        :year,
        :name
      ] }

      SpreeAdminInsights::ReportDb[unordered_group_by_months].order(:year, :number)
    end

    def grouped_by_months_mysql(order_shipment_rates, revenue_table)
      SpreeAdminInsights::ReportDb[order_shipment_rates].
        join(:spree_shipping_methods, id: :order_shipment_rates__shipping_method_id).
        join(revenue_table, months_name: :order_shipment_rates__months_name).
        group(:months_name, :spree_shipping_methods__id).
        order(:year, :number).
        select { [
        order_shipment_rates__order_id,
        spree_shipping_methods__id,
        Sequel.as(SUM(shipping_charge), :shipping_charge),
        revenue,
        shipping_method_id,
        Sequel.as(concat(month_name, ' ', COALESCE(year, '2016')), :months_name),
        Sequel.as(ROUND((SUM(shipping_charge) / revenue) * 100, 2), :shipping_cost_percentage),
        number,
        year,
        name
      ] }
    end
  end
end
