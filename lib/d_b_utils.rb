module DBUtils
  def self.month_name(date_field)
    case adapter
      when :postgresql
        date_format(date_field, 'Month')
      else
        Sequel.function(:MONTHNAME, date_field)
    end
  end

  def self.month_number(date_field)
    case adapter
      when :postgresql
        date_format(date_field, 'fmMM')
      else
        Sequel.function(:MONTH, date_field)
    end
  end

  def self.year(date_field)
    case adapter
      when :postgresql
        date_format(date_field, 'YYYY')
      else
        Sequel.function(:YEAR, date_field)
    end
  end

  def self.date_format(date_field, format)
    case adapter
      when :postgresql
        Sequel.function(:TO_CHAR, date_field, format)
      else
        Sequel.function(:DATE_FORMAT, date_field, format)
    end
  end

  def self.adapter
    @adapter ||= (ActiveRecord::Base.configurations[Rails.env] ||
      Rails.configuration.database_configuration[Rails.env])['adapter'].to_sym
  end
end
