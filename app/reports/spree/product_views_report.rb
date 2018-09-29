module Spree
  class ProductViewsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS = { product_name: :string, views: :integer, users: :integer, guest_sessions: :integer }
    SEARCH_ATTRIBUTES = { start_date: :product_view_from, end_date: :product_view_till, name: :name}
    SORTABLE_ATTRIBUTES = [:product_name, :views, :users, :guest_sessions]

    deeplink product_name: { template: %Q{<a href="/admin/products/{%# o.product_slug %}" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :views, :users, :guest_sessions]
      end
    end

    def report_query
      viewed_events =
        Spree::Product
          .where(Spree::Product.arel_table[:name].matches(search_name))
          .joins(event_scope)
          .where(report_source_table.to_sym => { created_at: reporting_period })
          .group('product_name', 'product_slug', "#{report_source_table}.actor_id", "#{report_source_table}.session_id")
          .select(
            'spree_products.name           as product_name',
            'spree_products.slug           as product_slug',
            'COUNT(*)                      as total_views_per_session',
            "#{report_source_table}.session_id  as session_id",
            "#{report_source_table}.actor_id    as actor_id"
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

    private def search_name
      search[:name].present? ? "%#{ search[:name] }%" : '%'
    end

    private def report_source_table
      Spree::Config.events_tracker_archive_data ? 'spree_archived_page_events' : 'spree_page_events'
    end

    private def event_scope
      Spree::Config.events_tracker_archive_data ? :archived_page_view_events : :page_view_events
    end

  end
end
