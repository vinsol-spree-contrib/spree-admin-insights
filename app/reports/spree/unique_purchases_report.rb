module Spree
  class UniquePurchasesReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { options_values: :string, product_name: :string, sold_count: :integer, users: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :orders_completed_from, end_date: :orders_completed_till, name: :product_name }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :sold_count, :users]

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}/variants/{%# o.variant_id %}/edit" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :options_values, :variant_id, :sold_count, :users]
      end
    end

    def report_query
      user_count_sql = '(COUNT(DISTINCT(spree_orders.email)))'
      purchases_by_variant =
        Spree::LineItem
          .joins(:order)
          .joins(variant: :option_values)
          .joins(:product)
          .where(Spree::Product.arel_table[:name].matches(search_name))
          .where(spree_orders: { state: 'complete', completed_at: reporting_period })
          .group('variant_id', 'spree_variants.sku', 'spree_products.slug', 'spree_products.name')
          .select(
            'spree_products.slug  as product_slug',
            'spree_variants.id    as variant_id',
            'spree_products.name  as product_name',
            'SUM(quantity)        as sold_count',
            "GROUP_CONCAT(DISTINCT spree_option_values.name SEPARATOR ', ') as options_values",
            "#{ user_count_sql }  as users"
          )
    end

  end
end
