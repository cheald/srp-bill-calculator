module Plans
  class Base
    attr_reader :monthly_usage

    def initialize(logger)
      @logger = logger
      @total = 0
    end

    def add(date, hour, kwh)
      @demand_total ||= 0
      @monthly_usage ||= 0
      @peak ||= 0

      d = Date.strptime(date, "%m/%d/%Y")
      h = Time.parse(hour).hour

      @last_date = d
      @last_hour = h

      if (d.day == 1 && h == 0)
        demand_for_month = @peak * demand_rate(d, h)
        @demand_total += demand_for_month
        @logger.debug "Demand charge for month: #{@peak} kW @ #{demand_rate(d, h)} = #{demand_for_month}"
        @logger.debug "Total demand charges so far: #{@demand_total}"
        @peak = 0
        @monthly_usage = 0
      end
      k = demand_usage(d, h, kwh.to_f)
      @peak = k if k > @peak
      @monthly_usage += k

      v = cost date, hour, kwh
      @logger.debug format("%25s %15s %-15s %2.2f kWh costs $%2.2f", self.class.to_s, date, hour, kwh, v)
      @total += v
      @logger.debug "Total is #{@total}"
    end

    def holiday?(date)
      return false
      (date.month == 1 && date.day == 1) || # New Years
      (date.month == 7 && date.day == 4) || # July 4
      (date.month == 12 && date.day == 25)  # Christmas
      # last monday of May, Memorial Day
      # first monday of Sept, Labor Day
      # fourth thursday of November, Thanksgiving
    end

    def demand_usage(date, hour, kwh)
      0
    end

    def demand_rate(date, hour)
      0
    end

    def total
      @total + total_demand_charge
    end

    def total_demand_charge
      @demand_total + (@peak * demand_rate(@last_date, @last_hour))
    end

    def cost(date, hour, kwh)
      date = Date.strptime date, "%m/%d/%Y"
      kwh = kwh.to_f
      hour = Time.parse(hour).hour
      rate(date, hour) * kwh.to_f
    end

    def to_s
      format "%-30s\t$%2.2f", self.class.to_s, total
    end
  end
end
