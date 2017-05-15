module Spree
  class ProductViewsToPurchasesReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS = { product_name: :string, views: :integer, purchases: :integer, purchase_to_view_ratio: :integer }
    SEARCH_ATTRIBUTES = { start_date: :product_view_from, end_date: :product_view_till }
    SORTABLE_ATTRIBUTES = [:product_name, :views, :purchases]

    def initialize(options)
      super
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate(options = {})
      purchases_by_product = ::SpreeAdminInsights::ReportDb[:spree_line_items___line_items]
                               .join(:spree_variants___variants, id: :variant_id)
                               .join(:spree_products___products, id: :variants__product_id)
                               .join(:spree_orders___orders, id: :line_items__order_id)
                               .where(orders__state: 'complete')
                               .where(orders__created_at: @start_date..@end_date)
                               .group(:products__id)
                               .select { [
        Sequel.as(Sequel.function(:SUM, :line_items__quantity), :purchases),
        Sequel.as(:products__name, :product_name),
        Sequel.as(:products__id, :product_id)
      ] }.as(:purchases_by_product)


      case DBUtils.adapter
        when :postgresql
          generate_postgresql(purchases_by_product)
        else
          generate_mysql(purchases_by_product)
      end
    end

    def select_columns(dataset)
      base_columns = [:product_name, :purchases]

      case DBUtils.adapter
        when :postgresql
          dataset.select { base_columns | [
            :views,
            Sequel.as(Sequel.lit("ROUND((purchases / views :: NUMERIC), 2)"), :purchase_to_view_ratio)
          ] }
        else
          dataset.select { base_columns | [
            COUNT('*').as(:views),
            Sequel.as(Sequel.lit("ROUND(purchases / COUNT('*'), 2)"), :purchase_to_view_ratio)
          ] }
      end
    end

    private

    def generate_postgresql(purchases_by_product)
      view_events = ::SpreeAdminInsights::ReportDb[:spree_page_events___page_events]
                      .where(page_events__target_type: 'Spree::Product', page_events__activity: 'view')
                      .group(:target_id)
                      .select { [
        Sequel.as(Sequel.function(:COUNT, '*'), :views),
        :page_events__target_id
      ] }.as(:view_events)

      not_ordered_result = ::SpreeAdminInsights::ReportDb[line_items(purchases_by_product)]
                             .join(::SpreeAdminInsights::ReportDb[view_events], target_id: :product_id)
                             .distinct(:product_id)

      ::SpreeAdminInsights::ReportDb[not_ordered_result].order(sortable_sequel_expression)
    end

    def generate_mysql(purchases_by_product)
      ::SpreeAdminInsights::ReportDb[line_items(purchases_by_product)]
        .join(:spree_page_events___page_events, page_events__target_id: :product_id)
        .where(page_events__target_type: 'Spree::Product', page_events__activity: 'view')
        .group(:product_id)
        .order(sortable_sequel_expression)
    end

    def line_items(purchases_by_product)
      line_items = ::SpreeAdminInsights::ReportDb[purchases_by_product]
                     .join(:spree_variants___variants, product_id: :purchases_by_product__product_id)
                     .join(:spree_line_items___line_items, variant_id: :variants__id)

      columns = [:line_items__quantity, :line_items__id, :line_items__variant_id,
        :purchases_by_product__purchases, :purchases_by_product__product_name, :purchases_by_product__product_id]

      case DBUtils.adapter
        when :postgresql
          line_items.distinct(:purchases_by_product__product_id).select(*columns).as(:line_items)
        else
          line_items.group(:purchases_by_product__product_id).select(*columns).as(:line_items)
      end
    end
  end
end
