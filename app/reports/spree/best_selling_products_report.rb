module Spree
  class BestSellingProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :sold_count
    HEADERS                    = { options_values: :string, product_name: :string, sold_count: :integer}
    SEARCH_ATTRIBUTES          = { start_date: :orders_completed_from, end_date: :orders_completed_to, name: :product_name }
    SORTABLE_ATTRIBUTES        = [:product_name, :sold_count]

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}/variants/{%# o.variant_id %}/edit" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :sold_count, :variant_id, :options_values]
      end
    end

    private def report_query
      Spree::LineItem
        .joins(:order)
        .joins(variant: :option_values)
        .joins(:product)
        .joins(:inventory_units)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(spree_orders: { created_at: reporting_period, state: 'complete' })
        .where.not(spree_inventory_units: { state: 'returned' })
        .group(:variant_id, :product_name, :product_slug, 'spree_variants.sku')
        .select(
          'spree_products.name        as product_name',
          'spree_products.slug        as product_slug',
          'spree_variants.id          as variant_id',
          'spree_variants.sku         as sku',
          "GROUP_CONCAT(DISTINCT spree_option_values.name SEPARATOR ', ') as options_values",
          'SUM(spree_inventory_units.quantity) as sold_count'
        )
    end

  end
end
