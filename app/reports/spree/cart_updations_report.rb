module Spree
  class CartUpdationsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { options_values: :string, product_name: :string, updations: :integer, quantity_increase: :integer, quantity_decrease: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :product_updated_from, end_date: :product_updated_to, name: :product_name }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :updations, :quantity_increase, :quantity_decrease]

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}/variants/{%# o.variant_id %}/edit" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :updations, :quantity_increase, :options_values, :variant_id, :quantity_decrease]
      end
    end

    def report_query
      quantity_increase_sql = "CASE WHEN quantity > 0 then spree_cart_events.quantity ELSE 0 END"
      quantity_decrease_sql = "CASE WHEN quantity < 0 then spree_cart_events.quantity ELSE 0 END"

      Spree::CartEvent
        .updated
        .joins(variant: :product)
        .joins(variant: :option_values)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(created_at: reporting_period)
        .group('product_name', 'product_slug', 'spree_variants.sku')
        .select(
          'spree_products.name              as product_name',
          'spree_products.slug              as product_slug',
          'spree_variants.id               as variant_id',
          'spree_variants.sku               as sku',
          'count(spree_products.name)       as updations',
          "GROUP_CONCAT(DISTINCT spree_option_values.name SEPARATOR ', ') as options_values",
          "SUM(#{ quantity_increase_sql })  as quantity_increase",
          "SUM(#{ quantity_decrease_sql })  as quantity_decrease"
        )
    end

  end
end
