module Spree
  class ReturnedProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { options_values: :string, product_name: :string, return_count: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :product_returned_from, end_date: :product_returned_till, name: :product_name }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :return_count]

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}/variants/{%# o.variant_id %}/edit" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:options_values, :variant_id, :product_name, :return_count, :product_slug]
      end
    end

    private def report_query
      Spree::ReturnAuthorization.joins(return_items: [{ inventory_unit: { variant: :product } }, { inventory_unit: { variant: :option_values}}])
        .where(spree_return_items: { created_at: reporting_period })
        .group('spree_variants.id', 'spree_products.name', 'spree_products.slug', 'spree_variants.sku')
        .select(
          'spree_products.name                  as product_name',
          'spree_products.slug                  as product_slug',
          'spree_variants.sku                   as sku',
          'spree_variants.id                    as variant_id',
          'SUM(spree_inventory_units.quantity)  as return_count',
          "GROUP_CONCAT(DISTINCT spree_option_values.name SEPARATOR ', ') as options_values",
        )
    end

    private def search_name
      search[:name].present? ? "%#{ search[:name] }%" : '%'
    end
  end
end
