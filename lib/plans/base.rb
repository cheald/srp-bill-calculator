require "time"

module Plans
  class Base
    attr_reader :monthly_usage, :total_kwh

    def initialize(logger, demand_schedule)
      @logger = logger
      @total = 0
      @demand_schedule = demand_schedule
    end

    def demand_for_period(year, month)
      return @peak unless @demand_schedule
      key = Date.new(year, month, 1).strftime("%Y-%m")
      @demand_schedule.fetch(key, @peak)
    end

    def add(date, hour, kwh)
      @demand_total ||= 0
      @monthly_usage ||= 0
      @usage_by_month ||= {}
      @peak ||= 0
      @total_kwh ||= 0

      d = date
      h = Time.parse(hour).hour
      m = Time.parse(hour).min

      @usage_by_month[d.strftime("%Y-%m")] ||= 0
      @usage_by_month[d.strftime("%Y-%m")] += kwh.to_f

      @first_date ||= d
      @last_date = d
      @last_hour = h

      if (d.day == 1 && h == 0 && m == 0)
        peak = demand_for_period(d.year, d.month)
        demand_for_month = peak * demand_rate(d, h)
        @demand_total += demand_for_month
        @logger.debug "Demand charge for month: #{@peak} kW @ #{demand_rate(d, h)} = #{demand_for_month}"
        @logger.debug "Total demand charges so far: #{@demand_total}"
        @peak = 0
        @monthly_usage = 0
      end
      k = demand_usage(d, h, kwh.to_f)
      @peak = k if k > @peak
      @monthly_usage += k
      @total_kwh += kwh.to_f

      v = cost date, hour, kwh
      # @logger.debug format("%25s %15s %-15s %2.2f kWh costs $%2.2f", self.class.to_s, date, hour, kwh, v)
      @total += v
      # @logger.debug "Total is #{@total}"
    end

    def holiday?(date)
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
      @total + total_demand_charge + total_fixed_charges
    end

    def energy_total
      @total + total_demand_charge
    end

    def billing_periods
      billing_periods = (@last_date - @first_date).to_i / (365.25 / 12.0)
    end

    # Compute the fixed charges (ie, connection fees) for the whole period
    # This uses a float to estimate an amortized cost for partial billing periods
    def total_fixed_charges
      fixed_charges * billing_periods
    end

    def total_demand_charge
      peak = demand_for_period(@last_date.year, @last_date.month)
      @demand_total + (peak * demand_rate(@last_date, @last_hour))
    end

    def cost(date, hour, kwh)
      kwh = kwh.to_f
      hour = Time.parse(hour).hour
      rate(date, hour) * kwh.to_f
    end

    def display_name
      self.class.to_s.gsub("Plans::", "")
    end

    def colorize_string(string, code)
      "\e[0;#{code};49m#{string}\e[0m"
    end

    def notes
    end

    def self.print_header
      puts colorize_string(format("%-30s\t%8s\t%8s\t%8s\t%8s\t%-8s",
                                  "Plan Name",
                                  "Total",
                                  "Energy",
                                  "Demand",
                                  "Fees",
                                  "Notes"), 94)
      puts "-" * 101
    end

    def to_s
      format "%-30s\t%8s\t%8s\t%8s\t%8s\t%s",
        display_name,
        format("$%2.2f", total),
        format("$%2.2f", @total),
        format("$%2.2f", total_demand_charge),
        format("$%2.2f", total_fixed_charges),
        colorize_string(notes, 37)
    end
  end
end
