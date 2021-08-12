module Spree
  class UsersNotConvertedReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :user_email
    HEADERS                    = { user_email: :string, signup_date: :date }
    SEARCH_ATTRIBUTES          = { start_date: :users_created_from, end_date: :users_created_till, email_cont: :user_email }
    SORTABLE_ATTRIBUTES        = [:user_email, :signup_date]

    def paginated?
      true
    end

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:user_email, :signup_date]

        def signup_date
          @signup_date.to_date.strftime("%B %d, %Y")
        end
      end
    end

    def paginated_report_query
      report_query
        .limit(records_per_page)
        .offset(current_page)
    end

    def record_count_query
      Spree::Report::QueryFragments.from_subquery(report_query).project(Arel.star.count)
    end

    def report_query
      users = Spree::User.arel_table
      orders = Spree::Order.arel_table
      Spree::User
        .where(created_at: reporting_period)
        .where(Spree::User.arel_table[:email].matches(email_search))
        .where('NOT EXISTS (?)', Spree::Order
          .where(orders[:user_id].eq(users[:id]).and(
            orders[:completed_at].not_eq(nil))
          )
        )
        .select(
          "spree_users.email       as  user_email",
          "spree_users.created_at  as signup_date")
    end

    private def email_search
      search[:email_cont].present? ? "%#{ search[:email_cont] }%" : '%'
    end

  end
end
