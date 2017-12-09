module Spree
  class BestSellingProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :sold_count
    HEADERS                    = { sku: :string, product_name: :string, sold_count: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :orders_completed_from, end_date: :orders_completed_to }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :sold_count]

    deeplink product_name: {
      template: %(
        <a href=
        "#{Spree::Core::Engine.routes.url_helpers.edit_admin_product_path('@@@')}"
        target="_blank">{%# o.product_name %}</a>
      ).sub!('@@@', '{%# o.product_slug %}')
    }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :sku, :sold_count]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      Spree::LineItem
        .joins(:order)
        .joins(:variant)
        .joins(:product)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(spree_orders: { state: 'complete' })
        .where(spree_orders: { completed_at: reporting_period })
        .group(:variant_id, :product_name, :product_slug, 'spree_variants.sku')
        .select(
          'spree_products.name as product_name',
          'spree_products.slug as product_slug',
          'spree_variants.sku  as sku',
          'sum(quantity)       as sold_count'
        )
    end

    private def search_name
      search[:name].present? ? "%#{ search[:name] }%" : '%'
    end

  end
end
