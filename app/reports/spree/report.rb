module Spree
  class Report
    attr_accessor :sortable_attribute, :sortable_type

    def no_pagination?
      false
    end

    def generate(options = {})
      raise 'Please define this method in inherited class'
    end

    def initialize(options)
      @search = options.fetch(:search, {})
      start_date = @search[:start_date]
      @start_date = start_date.present? ? Date.parse(start_date) : Date.new(Date.current.year)

      end_date = @search[:end_date]
      # 1.day is added to date so that we can get current date records
      # since date consider time at midnight
      @end_date = (end_date.present? ? Date.parse(end_date) : Date.new(Date.current.year, 12, 30)) + 1.day
    end

    def header_sorted?(header)
      sortable_attribute.eql?(header)
    end

    def set_sortable_attributes(options, default_sortable_attribute)
      self.sortable_type ||= (options[:sort] && options[:sort][:type].eql?('desc')) ? :desc : :asc
      self.sortable_attribute = options[:sort] ? options[:sort][:attribute].to_sym : default_sortable_attribute
    end

    def sortable_sequel_expression
      sortable_type.eql?(:desc) ? Sequel.desc(sortable_attribute) : Sequel.asc(sortable_attribute)
    end

    def fill_missing_values(default_object, incomplete_result_set)
      complete_result_set = []
      year_month_list = (@start_date..@end_date).map { |date| [date.year, date.month] }.uniq
      year_month_list.each do |year_month|
        index = incomplete_result_set.index do |obj|
          obj[:year].to_s == year_month.first.to_s && obj[:number].to_s == year_month.second.to_s
        end
        if index
          complete_result_set.push(incomplete_result_set[index])
        else
          filling_object = default_object.merge({ year: year_month.first, number: year_month.second, months_name: [Date::MONTHNAMES[year_month.second], year_month.first].join(' ') })
          complete_result_set.push(filling_object)
        end
      end
      complete_result_set
    end

    def chart_json
      {
        chart: false,
        charts: []
      }
    end
  end
end
