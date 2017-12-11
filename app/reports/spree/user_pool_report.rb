module Spree
  class UserPoolReport < Spree::Report
    HEADERS             = { guest_users: :integer, active_users: :integer, new_sign_ups: :integer }
    SEARCH_ATTRIBUTES   = { start_date: :users_created_from, end_date: :users_created_till }
    SORTABLE_ATTRIBUTES = []

    class Result < Spree::Report::TimedResult
      charts DistributionColumnChart

      class Observation < Spree::Report::TimedObservation
        observation_fields active_users: 0, guest_users: 0, new_sign_ups: 0
      end
    end

    def report_query
      Report::QueryFragments
        .from_union(grouped_sign_ups, grouped_unique_visitors, grouped_guest_users)
        .group(*time_scale_columns)
        .order(*time_scale_columns_to_s)
        .project(
          *time_scale_columns,
          'SUM(active_users)  as active_users',
          'SUM(guest_users)   as guest_users',
          'SUM(new_sign_ups)  as new_sign_ups'
        )
    end

    private def grouped_sign_ups
      sign_ups = Spree::User.where(created_at: reporting_period).select(:id, *time_scale_selects)

      Report::QueryFragments.from_subquery(sign_ups)
        .group(*time_scale_columns, 'guest_users', 'active_users')
        .order(*time_scale_columns_to_s)
        .project(
          *time_scale_columns,
          '0          as guest_users',
          '0          as active_users',
          'COUNT(id)  as new_sign_ups'
        )
    end

    private def grouped_unique_visitors
      Report::QueryFragments.from_subquery(visitors)
        .group(*time_scale_columns, 'new_sign_ups')
        .order(*time_scale_columns_to_s)
        .project(
          *time_scale_columns,
          'COUNT(DISTINCT(session))   as guest_users',
          'COUNT(DISTINCT(user))  as active_users',
          '0                      as new_sign_ups'
        )
    end

    private def visitors
      Spree::PageEvent
        .where(created_at: reporting_period)
        .select(
          *time_scale_selects,
          'actor_id    as user',
          'session_id  as session'
        )
    end

    private def grouped_guest_users
      Report::QueryFragments.from_subquery(registered_users_visited)
        .group(*time_scale_columns)
        .project(
          *time_scale_columns,
          "-2 * COUNT(user_session) as guest_users",
          '0 as active_users',
          '0 as new_sign_ups'
        )
    end

    private def registered_users_visited
      Spree::PageEvent
        .where(created_at: reporting_period)
        .where.not(actor_id: nil)
        .group(:session_id, :actor_id, *time_scale_columns)
        .select(*time_scale_selects,
          'session_id as user_session',
          'actor_id as user'
        )
    end

  end
end
