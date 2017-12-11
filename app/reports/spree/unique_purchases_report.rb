module Spree
  class UniquePurchasesReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string, sold_count: :integer, users: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :orders_completed_from, end_date: :orders_completed_till }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :sold_count, :users]

    deeplink product_name: { template: %Q{<a href="/admin/products/{%# o.product_slug %}" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :sku, :sold_count, :users]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      user_count_sql = '(COUNT(DISTINCT(spree_orders.email)))'
      purchases_by_variant =
        Spree::LineItem
          .joins(:order)
          .joins(:variant)
          .joins(:product)
          .where(spree_orders: { state: 'complete', completed_at: reporting_period })
          .group('variant_id', 'spree_variants.sku', 'spree_products.slug', 'spree_products.name')
          .select(
            'spree_variants.sku   as sku',
            'spree_products.slug  as product_slug',
            'spree_products.name  as product_name',
            'SUM(quantity)        as sold_count',
            "#{ user_count_sql }  as users"
          )
    end

  end
end
