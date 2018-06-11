module Spree
  class TrendingSearchReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :occurrences
    HEADERS                    = { searched_term: :string, occurrences: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :start_date, end_date: :end_date, keywords_cont: :keyword }
    SORTABLE_ATTRIBUTES        = [:occurrences]

    def paginated?
      true
    end

    class Result < Spree::Report::Result
      charts FrequencyDistributionPieChart

      class Observation < Spree::Report::Observation
        observation_fields [:searched_term, :occurrences]
      end
    end

    deeplink searched_term: { template: %Q{<a href='/products?utf8=%E2%9C%93&keywords={%# o['searched_term'] %}' target="_blank">{%# o['searched_term'] %}</a>} }

    def paginated_report_query
      report_query
        .take(records_per_page)
        .skip(current_page)
    end

    def record_count_query
      Spree::Report::QueryFragments.from_subquery(report_query).project(Arel.star.count)
    end

    def report_query
      Spree::Report::QueryFragments.from_subquery(searches)
        .project("count(searched_term) as occurrences", "searched_term")
        .group("searched_term")
    end

    private def searches
      report_source
        .where(activity: 'search')
        .where(created_at: reporting_period)
        .where(report_source.arel_table[:search_keywords].matches(keyword_search))
        .select("search_keywords as searched_term")
    end

    private def keyword_search
      search[:keywords_cont].present? ? "%#{ search[:keywords_cont] }%" : '%'
    end

    private def report_source
      Spree::Config.events_tracker_archive_data ? Spree::ArchivedPageEvent : Spree::PageEvent
    end

  end
end
