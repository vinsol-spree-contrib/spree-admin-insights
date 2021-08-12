module Spree
  class UsersWhoRecentlyPurchasedReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :user_email
    HEADERS                    = { user_email: :string, purchase_count: :integer, total_purchased: :decimal, last_purchase_date: :date, last_purchased_order_number: :string }
    SEARCH_ATTRIBUTES          = { start_date: :start_date, end_date: :end_date, email_cont: :email }
    SORTABLE_ATTRIBUTES        = [:user_email, :purchase_count, :last_purchase_date, :total_purchased]

    deeplink last_purchased_order_number: { template: %Q{<a href="/store/admin/orders/{%# o.last_purchased_order_number %}/edit" target="_blank">{%# o.last_purchased_order_number %}</a>} }

    def paginated?
      true
    end

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:user_email, :last_purchased_order_number, :last_purchase_date, :purchase_count, :total_purchased]

        def last_purchase_date
          @last_purchase_date.to_date.strftime("%B %d, %Y")
        end
      end
    end

    def record_count_query
      Spree::Report::QueryFragments.from_subquery(report_query).project(Arel.star.count)
    end

    def report_query
      ar_orders = Arel::Table.new(:spree_orders)
      results = Arel::Table.new(:results)
      Spree::Report::QueryFragments
        .from_subquery(all_orders_with_users)
        .join(ar_orders)
        .on(
          ar_orders[:email].eq(results[:user_email]).and(
            ar_orders[:completed_at].eq(results[:last_purchase_date])
          )
        )
        .project(
          "results.user_email         as user_email",
          "spree_orders.number        as last_purchased_order_number",
          "results.last_purchase_date as last_purchase_date",
          "results.purchased_count    as purchase_count",
          "results.total_purchased    as total_purchased"
        )
    end


    def paginated_report_query
      report_query
        .take(records_per_page)
        .skip(current_page)
    end

    private def all_orders_with_users
      Spree::Order
        .where(Spree::Order.arel_table[:email].matches(email_search))
        .where(spree_orders: { completed_at: reporting_period })
        .select(
          "spree_orders.email             as user_email",
          "max(spree_orders.completed_at) as last_purchase_date",
          "count(spree_orders.email)      as purchased_count",
          "SUM(spree_orders.total)        as total_purchased"
        )
        .group(
          "user_email"
        )
    end

    private def email_search
      search[:email_cont].present? ? "%#{ search[:email_cont] }%" : '%'
    end
  end
end
