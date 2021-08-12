module Spree
  class ProductViewsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS = { product_name: :string, views: :integer, users: :integer, guest_sessions: :integer }
    SEARCH_ATTRIBUTES = { start_date: :product_view_from, end_date: :product_view_till, name: :name}
    SORTABLE_ATTRIBUTES = [:product_name, :views, :users, :guest_sessions]

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :views, :users, :guest_sessions]
      end
    end

    def report_query
      viewed_events =
        Spree::Product
          .where(Spree::Product.arel_table[:name].matches(search_name))
          .joins(:page_view_events)
          .where(spree_page_events: { created_at: reporting_period })
          .group('product_name', 'product_slug', 'spree_page_events.actor_id', 'spree_page_events.session_id')
          .select(
            'spree_products.name           as product_name',
            'spree_products.slug           as product_slug',
            'COUNT(*)                      as total_views_per_session',
            'spree_page_events.session_id  as session_id',
            'spree_page_events.actor_id    as actor_id'
          )
      Spree::Report::QueryFragments
        .from_subquery(viewed_events)
        .group('product_name', 'product_slug')
        .project(
          'product_name',
          'product_slug',
          'SUM(total_views_per_session)                    as views',
          'COUNT(DISTINCT actor_id)                        as users',
          '(COUNT(DISTINCT session_id) - COUNT(actor_id))  as guest_sessions'
        )
    end

  end
end
