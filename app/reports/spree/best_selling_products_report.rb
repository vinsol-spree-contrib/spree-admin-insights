module Spree
  class BestSellingProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :sold_count
    HEADERS = { sku: :string, product_name: :string, sold_count: :integer }
    SEARCH_ATTRIBUTES = { start_date: :orders_completed_from, end_date: :orders_completed_to }
    SORTABLE_ATTRIBUTES = [:product_name, :sku, :sold_count]

    def initialize(options)
      super
      @name = @search[:name].present? ? "%#{ @search[:name] }%" : '%'
      @sortable_type = :desc if options[:sort].blank?
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate
      ::SpreeAdminInsights::ReportDb[:spree_line_items___line_items].
      join(:spree_orders___orders, id: :order_id).
      join(:spree_variants___variants, variants__id: :line_items__variant_id).
      join(:spree_products___products, products__id: :variants__product_id).
      where(orders__state: 'complete').
      where(orders__completed_at: @start_date..@end_date). #filter by params
      group(:variant_id, :variants__sku, :products__name).
      order(sortable_sequel_expression)
    end

    def select_columns(dataset)
      dataset.select{[
        products__name.as(product_name),
        Sequel.as(Sequel.lit("CASE variants.sku WHEN '' THEN products.name ELSE variants.sku END"), :sku),
        sum(quantity).as(sold_count)
      ]}
    end
  end
end
