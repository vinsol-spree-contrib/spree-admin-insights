module Spree
  class ProductViewsToCartAdditionsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { product_name: :string, views: :integer, cart_additions: :integer, cart_to_view_ratio: :string }
    SEARCH_ATTRIBUTES          = { start_date: :product_view_from, end_date: :product_view_till, name: :product_name  }
    SORTABLE_ATTRIBUTES        = [:product_name, :views, :cart_additions]

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :views, :cart_additions, :cart_to_view_ratio]

        def cart_to_view_ratio
          (cart_additions.to_f / views.to_f).round(2)
        end
      end
    end

    def report_query
      cart_additions =
        Spree::CartEvent
          .added
          .joins(variant: :product)
          .where(created_at: reporting_period)
          .where(Spree::Product.arel_table[:name].matches(search_name))
          .group('spree_products.name', 'spree_products.slug')
          .select(
            'spree_products.name              as product_name',
            'spree_products.slug              as product_slug',
            'SUM(spree_cart_events.quantity)  as cart_additions'
          )
      total_views =
        Spree::Product
          .joins(:page_view_events)
          .group(:name)
          .select(
            'spree_products.name  as product_name',
            'COUNT(*)             as views'
          )

      Spree::Report::QueryFragments
        .from_join(cart_additions, total_views, "q1.product_name = q2.product_name")
        .project(
          'q1.product_name',
          'q1.product_slug',
          'q2.views',
          'q1.cart_additions'
        )
    end

  end
end
