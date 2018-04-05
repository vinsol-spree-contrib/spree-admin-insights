module Spree
  class BestSellingProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :sold_count
    HEADERS                    = { sku: :string, product_name: :string, sold_count: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :orders_completed_from, end_date: :orders_completed_to }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :sold_count]

    deeplink product_name: { template: %Q{<a href="/admin/products/{%# o.product_slug %}" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :sku, :sold_count]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      if Spree.version.to_f >= 3.3
        return query_with_inventory_unit_quantities
      else
        return query_without_inventory_unit_quantities
      end
    end

    private def search_name
      search[:name].present? ? "%#{ search[:name] }%" : '%'
    end

    private def query_with_inventory_unit_quantities
      Spree::LineItem
        .joins(:order)
        .joins(:variant)
        .joins(:product)
        .joins(:inventory_units)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(spree_orders: { state: 'complete' })
        .where(spree_orders: { completed_at: reporting_period })
        .where.not(spree_inventory_units: { state: 'returned' })
        .group(:variant_id, :product_name, :product_slug, 'spree_variants.sku')
        .select(
          'spree_products.name        as product_name',
          'spree_products.slug        as product_slug',
          'spree_variants.sku         as sku',
          'sum(spree_inventory_units.quantity) as sold_count'
        )
    end

    private def query_without_inventory_unit_quantities
      Spree::LineItem
        .joins(:order)
        .joins(:variant)
        .joins(:product)
        .joins(:inventory_units)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(spree_orders: { state: 'complete' })
        .where(spree_orders: { completed_at: reporting_period })
        .where.not(spree_inventory_units: { state: 'returned' })
        .group(:variant_id, :product_name, :product_slug, 'spree_variants.sku')
        .select(
          'spree_products.name        as product_name',
          'spree_products.slug        as product_slug',
          'spree_variants.sku         as sku',
          'count(spree_line_items.id) as sold_count'
        )
    end
  end
end
