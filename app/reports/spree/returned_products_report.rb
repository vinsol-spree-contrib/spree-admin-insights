module Spree
  class ReturnedProductsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string, return_count: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :product_returned_from, end_date: :product_returned_till, name: :name }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :return_count]

    deeplink product_name: {
      template: %(
        <a href=
        "#{Spree::Core::Engine.routes.url_helpers.edit_admin_product_path('@@@')}"
        target="_blank">{%# o.product_name %}</a>
      ).sub!('@@@', '{%# o.product_slug %}')
    }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:sku, :product_name, :return_count, :product_slug]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      Spree::ReturnAuthorization
        .joins(:return_items)
        .joins(:inventory_units)
        .joins(:variants)
        .joins(:products)
        .where(spree_return_items: { created_at: reporting_period })
        .group('spree_variants.id', 'spree_products.name', 'spree_products.slug', 'spree_variants.sku')
        .select(
          'spree_products.name       as product_name',
          'spree_products.slug       as product_slug',
          'spree_variants.sku        as sku',
          'COUNT(spree_variants.id)  as return_count'
        )
    end

  end
end
