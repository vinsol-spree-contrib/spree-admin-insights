module Spree
  class ProductViewsToPurchasesReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { product_name: :string, views: :integer, purchases: :integer, purchase_to_view_ratio: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :product_view_from, end_date: :product_view_till, name: :product_name }
    SORTABLE_ATTRIBUTES        = [:product_name, :views, :purchases]

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :views, :purchases, :purchase_to_view_ratio]

        def purchase_to_view_ratio # This is inconsistent across postgres and mysql
          (purchases.to_f / views.to_f).round(2)
        end
      end
    end

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}" target="_blank">{%# o.product_name %}</a>} }

    def report_query
      page_events_ar         = Arel::Table.new(:spree_page_events)
      purchase_line_items_ar = Arel::Table.new(:purchase_line_items)

      Spree::Report::QueryFragments.from_subquery(purchase_line_items, as: :purchase_line_items)
        .join(page_events_ar)
        .on(page_events_ar[:target_id].eq(purchase_line_items_ar[:product_id]))
        .where(page_events_ar[:target_type].eq(Arel::Nodes::Quoted.new('Spree::Product')))
        .where(page_events_ar[:activity].eq(Arel::Nodes::Quoted.new('view')))
        .group(purchase_line_items_ar[:product_id], purchase_line_items_ar[:product_name],
               purchase_line_items_ar[:product_slug], purchase_line_items_ar[:purchases])
        .project(
          'product_name',
          'product_slug',
          'COUNT(*) as views',
          'purchases'
        )
    end

    private def purchase_line_items
      Spree::LineItem
        .joins(:order)
        .joins(:variant)
        .joins(:product)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(spree_orders: { state: 'complete', created_at: reporting_period })
        .group('spree_products.id', 'spree_products.name')
        .select(
          'SUM(quantity)        as purchases',
          'spree_products.name  as product_name',
          'spree_products.slug  as product_slug',
          'spree_products.id    as product_id'
        )
    end

  end
end
