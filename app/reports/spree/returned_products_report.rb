module Spree
  class ReturnedProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS = { product_name: :string, sku: :string, return_count: :integer }
    SEARCH_ATTRIBUTES = { start_date: :product_returned_from, end_date: :product_returned_till }
    SORTABLE_ATTRIBUTES = [:product_name, :sku, :return_count]

    def initialize(options)
      super
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate
      SpreeReportify::ReportDb[:spree_return_authorizations].
      join(:spree_return_items, return_authorization_id: :spree_return_authorizations__id).
      join(:spree_inventory_units, spree_inventory_units__id: :inventory_unit_id).
      join(:spree_variants, spree_variants__id: :variant_id).
      join(:spree_products, id: :product_id).
      where(spree_return_items__created_at: @start_date..@end_date).
      group(:variant_id).
      order(sortable_sequel_expression)
    end

    def select_columns(dataset)
      dataset.select{[
        spree_products__name.as(product_name),
        spree_variants__sku.as(sku),
        Sequel.as(count(:variant_id), :return_count)
      ]}
    end
  end
end
