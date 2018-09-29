module Spree
  class CartUpdationsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { sku: :string, product_name: :string, updations: :integer, quantity_increase: :integer, quantity_decrease: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :product_updated_from, end_date: :product_updated_to }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :updations, :quantity_increase, :quantity_decrease]

    deeplink product_name: { template: %Q{<a href="/admin/products/{%# o.product_slug %}" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :updations, :quantity_increase, :sku, :quantity_decrease]

        def sku
          @sku.presence || @product_name
        end
      end
    end

    def report_query
      quantity_increase_sql = "CASE WHEN quantity > 0 then #{report_source_table}.quantity ELSE 0 END"
      quantity_decrease_sql = "CASE WHEN quantity < 0 then #{report_source_table}.quantity ELSE 0 END"

      report_source
        .updated
        .joins(variant: :product)
        .where(created_at: reporting_period)
        .group('product_name', 'product_slug', 'spree_variants.sku')
        .select(
          'spree_products.name              as product_name',
          'spree_products.slug              as product_slug',
          'spree_variants.sku               as sku',
          'count(spree_products.name)       as updations',
          "SUM(#{ quantity_increase_sql })  as quantity_increase",
          "SUM(#{ quantity_decrease_sql })  as quantity_decrease"
        )
    end

    private def report_source
      Spree::Config.events_tracker_archive_data ? Spree::ArchivedCartEvent : Spree::CartEvent
    end

    private def report_source_table
      Spree::Config.events_tracker_archive_data ? 'spree_archived_cart_events' : 'spree_cart_events'
    end
    
  end
end
