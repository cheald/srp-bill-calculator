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
      @months = 0
      @hours = 0
      @cost_by_hour = {}
      @cost_by_month = {}
      @gen_by_month = {}
      @gen_by_hour = {}
    end

    def add(datetime, kwh)
      @hours += 1
      @demand_total ||= 0
      @monthly_usage ||= 0
      @usage_total ||= 0
      @offset_total ||= 0
      @excess_gen ||= 0
      @usage_by_month ||= {}
      @readings_by_month ||= {}
      @total_kwh ||= 0
      @net_metered_kwh ||= 0
      @max_demand ||= 0
      @demands ||= []

      d = datetime
      h = datetime.hour
      m = datetime.min

      pre_offset = kwh
      @usage_total += kwh
      kwh = offset datetime, kwh
      capped_kwh = [@options[:loadcap], kwh].min
      kwh = capped_kwh

      gen_kwh = (pre_offset - kwh)
      @offset_total += gen_kwh
      @gen_by_month[d.month] ||= 0
      @gen_by_month[d.month] += gen_kwh
      @gen_by_hour[h] ||= 0
      @gen_by_hour[h] += gen_kwh
      @excess_gen -= kwh if kwh < 0

      # @logger.debug "pre_offset: #{pre_offset}, kwh: #{kwh}"
      # When we have a flat net metering buyback rate, us it.
      # Otherwise, we just count this as a kWh credit at retail rates
      if kwh < 0 && net_metering_rate != 0
        @net_metered_kwh -= kwh
        kwh = 0
      end

      datekey = d.strftime("%Y-%m")

      @usage_by_month[datekey] ||= 0
      @usage_by_month[datekey] += kwh
      @readings_by_month[datekey] ||= 0
      @readings_by_month[datekey] += 1

      @first_date ||= d
      @last_date = d
      @last_hour = h

      new_month(d) if (d.day == 1 && h == 0 && m == 0)

      k = add_demand d, kwh
      @max_demand = k if k > @max_demand
      @demands << k if k > 0

      @monthly_usage += k
      @total_kwh += kwh

      v = cost datetime, datetime, kwh
      @cost_by_hour[h] ||= 0
      @cost_by_hour[h] += v
      @cost_by_month[d.month] ||= 0
      @cost_by_month[d.month] += v
      # @logger.debug format("%25s %15s %-15s %2.2f kWh costs $%2.2f", self.class.to_s, date, hour, kwh, v)
      @total += v
      # @logger.debug "Total is #{@total}"
    end

    def add_demand(date, kwh)
      datekey = date.strftime("%Y-%m")
      demand_by_month[datekey] ||= []

      k = [demand_usage(date, date.hour, kwh), 0].max
      demand_by_month[datekey] << k if k > 0

      return k
    end

    def demand_by_month
      @demand_by_month ||= {}
    end

    def demand_for_period(date)
      key = date.strftime("%Y-%m")
      demand = (demand_by_month[key] || [0]).max
      return demand || 0 unless @demand_schedule
      @demand_schedule.fetch(key, demand)
    end

    def new_month(date)
      # Look at the previous month's data
      d = date - 86400
      demand = demand_for_period(d) || 0
      demand_charge = demand_cost(demand, d, nil)
      @demand_total += demand_charge
      @logger.debug "#{format "%40s", display_name} - #{d.strftime "%Y-%m"} - Cost #{format "$%2.02f", demand_charge} (#{format "%2.1f", demand} kW demand)" if demand_charge > 0

      @monthly_usage = reset_monthly_usage
      @months += 1
    end

    def reset_monthly_usage
      0
    end

    def offset(_date, kwh)
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

    def net_metering_rate
      0
    end

    def net_metered_rebate
      @net_metered_kwh * net_metering_rate
    end

    def total
      usage_total + total_demand_charge + total_fixed_charges - net_metered_rebate
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
      # @logger.debug "Logging #{demand} demand at a rate of #{demand_rate(date, hour)}"
      # exit if demand > 0
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
      puts colorize_string(format("%-30s\t%8s\t%8s\t%8s\t%8s\t%8s\t%6s\t%-8s\t%-8s\t%-8s\t%-8s",
                                  "Plan Name",
                                  "Total",
                                  "Avg/Day",
                                  "Energy",
                                  "Demand",
                                  "Fees",
                                  "Usage (kWh)",
                                  "Gen (kWh)",
                                  "Gen/Day (kWh)",
                                  "Excess (kWh)",
                                  "Demand (kW) avg ± stddev",
                                  "Notes"), 94)
      puts "-" * 200
    end

    def extra_notes
      # return
      if @gen_by_month.values.any? { |v| v > 0 }
        puts "-" * 120
        puts display_name

        print "\t\t\t"
        puts (1..12).map { |i| colorize_string format("%-8s", Date::ABBR_MONTHNAMES[i]), 90 }.join("\t")
        ms = @gen_by_month.keys.sort.map do |k|
          "#{format "%-6.1fkw", @gen_by_month[k]}"
        end
        print colorize_string "Generation by month:\t", 90
        puts "#{ms.join("\t")}"

        mcs = @cost_by_month.keys.sort.map do |k|
          "#{format "$%-8.02f", @cost_by_month[k]}"
        end
        print colorize_string "Cost by month:\t\t", 90
        puts "#{mcs.join("\t")}"

        puts ""
        print "\t\t\t"
        puts (0..23).map { |i| colorize_string format("%-5s", i), 90 }.join("\t")
        hs = @gen_by_hour.keys.sort.map do |k|
          "#{format "%-5.1f", @gen_by_hour[k]}"
        end
        puts "Generation by hour:\t#{hs.join("\t")}"

        hcs = @cost_by_hour.keys.sort.map do |k|
          "#{format "$%-5.02f", @cost_by_hour[k]}"
        end
        puts "Cost by hour:\t\t#{hcs.join("\t")}"
        puts ""
      end
    end

    def to_s
      demand_avg = demand_min = demand_max = demand_stddev = 0
      if @demands.any?
        demand_sum = @demands.inject(&:+)
        demand_avg = demand_sum / @demands.length.to_f
        demand_stddev = @demands.map { |d| d - demand_avg }.map { |d| d * d }.inject(&:+) / @demands.length.to_f
      end
      format "%-30s\t%8s\t%8s\t%8s\t%8s\t%8s\t%8s\t%8s\t%8s\t%8s\t%8s",
        display_name,
        format("$%2.2f", total),
        format("$%2.2f", total / (@hours.to_f / 24.0)),
        format("$%2.2f", usage_total),
        format("$%2.2f", total_demand_charge),
        format("$%2.2f", total_fixed_charges),
        format("%2.1f", @usage_total),
        format("%2.1f", @offset_total),
        format("%2.1f", @offset_total / (@hours.to_f / 24.0)),
        format("%2.1f", @excess_gen),
        demand_avg > 0 ? format("%4.1f ± %-4.1f", demand_avg, demand_stddev) : "",
        colorize_string(notes, 37)
    end
  end
end
