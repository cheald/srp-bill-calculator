require "time"

module Plans
  class Base
    attr_reader :monthly_usage, :total_kwh

    def self.solar_eligible
      false
    end

    def initialize(logger, demand_schedule, options)
      @logger = logger
      @total = 0
      @demand_schedule = demand_schedule
      @options = options
    end

    def demand_for_period(date)
      key = date.strftime("%Y-%m")
      demand = (@demand_by_month[key] || [0]).max
      return demand || 0 unless @demand_schedule
      @demand_schedule.fetch(key, demand)
    end

    def add(datetime, kwh)
      @demand_total ||= 0
      @monthly_usage ||= 0
      @usage_total ||= 0
      @offset_total ||= 0
      @usage_by_month ||= {}
      @readings_by_month ||= {}
      @demand_by_month ||= {}
      @total_kwh ||= 0

      d = datetime
      h = datetime.hour
      m = datetime.min

      datekey = d.strftime("%Y-%m")
      @demand_by_month[datekey] ||= []

      pre_offset = kwh
      @usage_total += kwh
      kwh = offset datetime, datetime, kwh
      capped_kwh = [@options[:loadcap], kwh].min
      kwh = capped_kwh
      @offset_total += (pre_offset - kwh)

      @usage_by_month[datekey] ||= 0
      @usage_by_month[datekey] += kwh
      @readings_by_month[datekey] ||= 0
      @readings_by_month[datekey] += 1

      @first_date ||= d
      @last_date = d
      @last_hour = h

      new_month(d) if (d.day == 1 && h == 0 && m == 0)

      k = [demand_usage(d, h, kwh), 0].max
      @demand_by_month[datekey] << k if k > 0
      @monthly_usage += k
      @total_kwh += kwh

      v = cost datetime, datetime, kwh
      # @logger.debug format("%25s %15s %-15s %2.2f kWh costs $%2.2f", self.class.to_s, date, hour, kwh, v)
      @total += v
      @logger.debug "Total is #{@total}"
    end

    def new_month(date)
      # Look at the previous month's data
      d = date - 86400
      demand = demand_for_period(d) || 0
      demand_charge = demand_cost(demand, d, nil)
      @demand_total += demand_charge
      @logger.debug "Added #{demand_charge} (#{demand} kW demand)" if demand_charge > 0
      @monthly_usage = reset_monthly_usage
    end

    def reset_monthly_usage
      0
    end

    def offset(_date, _hour, kwh)
      kwh
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
      usage_total + total_demand_charge + total_fixed_charges
    end

    def usage_total
      [@total, 0].max
    end

    def energy_total
      usage_total + total_demand_charge
    end

    def billing_periods
      (@last_date - @first_date).to_i / (365.25 / 12.0 * 86400)
    end

    # Compute the fixed charges (ie, connection fees) for the whole period
    # This uses a float to estimate an amortized cost for partial billing periods
    def total_fixed_charges
      fixed_charges * billing_periods
    end

    def demand_cost(demand, date, hour)
      demand * demand_rate(date, hour)
    end

    def total_demand_charge
      peak = demand_for_period(@last_date) || 0
      @demand_total + demand_cost(peak, @last_date, @last_hour)
    end

    def cost(date, time, kwh)
      kwh = kwh
      rate(date, time.hour) * kwh
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
      puts colorize_string(format("%-30s\t%8s\t%8s\t%8s\t%8s\t%8s\t%8s\t%-8s",
                                  "Plan Name",
                                  "Total",
                                  "Energy",
                                  "Demand",
                                  "Fees",
                                  "Usage (kW)",
                                  "Gen (kW)",
                                  "Notes"), 94)
      puts "-" * 200
    end

    def to_s
      format "%-30s\t%8s\t%8s\t%8s\t%8s\t%8s\t%8s\t%s",
        display_name,
        format("$%2.2f", total),
        format("$%2.2f", usage_total),
        format("$%2.2f", total_demand_charge),
        format("$%2.2f", total_fixed_charges),
        format("%2.1f", @usage_total),
        format("%2.1f", @offset_total),
        colorize_string(notes, 37)
    end
  end
end
