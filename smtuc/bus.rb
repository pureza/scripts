class Bus
  attr_reader :id, :stops, :from, :to, :source_target, :target_source

  def initialize(id, stops, from, to)
    @id = id
    @stops = stops
    @from = from
    @to = to
    @source_target = Schedule.new()
    @target_source = Schedule.new()
  end
end

class Schedule

  attr_reader :weekdays_table, :saturday_table, :sunday_table
  
  def initialize()
    @weekdays_table = Hash.new { |hash, key| hash[key] = [] }
    @saturday_table = Hash.new { |hash, key| hash[key] = [] }
    @sunday_table = Hash.new { |hash, key| hash[key] = [] }
  end

  def add(day, hour, minute)
    case day
    when :weekdays
      @weekdays_table[hour] << minute
    when :saturday
      @saturday_table[hour] << minute
    else
      @sunday_table[hour] << minute
    end
  end
  
end
