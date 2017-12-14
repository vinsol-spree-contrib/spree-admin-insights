module Spree
  class CartAdditionsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string, additions: :integer, quantity_change: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :product_added_from, end_date: :product_added_to, name: :name }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :additions, :quantity_change]

    deeplink product_name: {
      template: %(
        <a href=
        "#{Spree::Core::Engine.routes.url_helpers.edit_admin_product_path('@@@')}"
        target="_blank">{%# o.product_name %}</a>
      ).sub!('@@@', '{%# o.product_slug %}')
    }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :additions, :quantity_change, :sku]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      Spree::CartEvent
        .added
        .joins(:variant)
        .joins(:product)
        .where(created_at: reporting_period)
        .group('product_name', 'product_slug', 'spree_variants.sku')
        .select(
          'spree_products.name             as product_name',
          'spree_products.slug             as product_slug',
          'spree_variants.sku              as sku',
          'count(spree_products.name)      as additions',
          'sum(spree_cart_events.quantity) as quantity_change'
        )
    end
  end
end
