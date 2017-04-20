module Spree
  class CartUpdationsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS = { sku: :string, product_name: :string, updations: :integer, quantity_increase: :integer, quantity_decrease: :integer }
    SEARCH_ATTRIBUTES = { start_date: :product_updated_from, end_date: :product_updated_to }
    SORTABLE_ATTRIBUTES = [:product_name, :sku, :updations, :quantity_increase, :quantity_decrease]

    def initialize(options)
      super
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate
      SpreeAdminInsights::ReportDb[:spree_cart_events___cart_events].
        join(:spree_variants___variants, id: :variant_id).
        join(:spree_products___products, id: :product_id).
        where(activity: 'update').
        where(cart_events__created_at: @start_date..@end_date).#filter by params
        group(:variant_id, :variants__sku, :products__name).
        order(sortable_sequel_expression)
    end

    def select_columns(dataset)
      dataset.select { [
        products__name.as(product_name),
        Sequel.as(Sequel.lit("CASE variants.sku WHEN '' THEN products.name ELSE variants.sku END"), :sku),
        Sequel.as(count(:products__name), :updations),
        Sequel.as(sum(Sequel.lit("CASE WHEN cart_events.quantity >= 0 THEN cart_events.quantity ELSE 0 END")), :quantity_increase),
        Sequel.as(sum(Sequel.lit("CASE WHEN cart_events.quantity <= 0 THEN cart_events.quantity ELSE 0 END")), :quantity_decrease)
      ] }
    end
  end
end
