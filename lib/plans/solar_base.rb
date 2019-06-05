require_relative "../sun_times"

module Plans
  class SolarBase < ::Plans::Base
    REL_MONTH_EFF = [0, 916, 918, 1185, 1330, 1358, 1305, 1222, 1209, 1128, 1099, 939, 861]
    OBS_MONTH_EFF = [0, 852, 947, 1142, 1185, 1324, 1447, 1298, 1268, 1136, 1076, 960, 950]

    def self.solar_eligible
      true
    end

    def cost_per_watt_installed
      @options[:cpw]
    end

    def system_size
      @options.fetch(:offset, 0).to_f
    end

    def system_cost
      format "$%2.0f", cost_per_watt_installed * system_size * 1000.0
    end

    def beta_pdf(x, a, b)
      return 0 if x < 0 || x > 1

      gab = Math.lgamma(a + b).first
      ga = Math.lgamma(a).first
      gb = Math.lgamma(b).first

      if x == 0.0 || x == 1.0
        Math.exp(gab - ga - gb) * x ** (a - 1) * (1 - x) ** (b - 1)
      else
        Math.exp(gab - ga - gb + Math.log(x) * (a - 1) + log1p(-x) * (b - 1))
      end
    end

    def log1p(x)
      # in C, this is volatile double y.
      # Not sure how to reproduce that in Ruby.
      y = 1 + x
      Math.log(y) - ((y - 1) - x).quo(y) # cancel errors with IEEE arithmetic
    end

    def offset(date, time, kwh)
      if @options[:pvwatts]
        offset_pvwatts(date, time, kwh)
      else
        offset_estimate(date, time, kwh)
      end
    end

    def offset_pvwatts(date, time, kwh)
      key = date.strftime("%-m-%-d-%-H")
      size, data = pvwatts_data
      x = data[key] / size * @options[:offset]
      kwh - x
    end

    def pvwatts_data
      @pvwatts_data ||= begin
        f = File.read(@options[:pvwatts])
        lines = []
        found = false
        size = 0
        f.lines.each do |l|
          if m = l.match(/DC System Size.*([\d.]+)/)
            size = m[1].to_f * 1000.0
          end
          found = true if l.match(/^"Month/)
          lines << l if found && !l.match(/^"Totals/)
        end

        data = {}
        CSV.parse(lines.join, headers: true).each do |row|
          data["%d-%d-%d" % [row["Month"], row["Day"], row["Hour"]]] = row["AC System Output (W)"].to_f
        end

        [size, data]
      end
    end

    def offset_estimate(date, time, kwh)
      offset = 0
      system_size = @options.fetch(:offset, 0).to_f

      efficiency = @options[:efficiency]
      system_size *= efficiency

      rise = SunTimes.new.rise(time, @options[:lat], @options[:long]).localtime
      set = SunTimes.new.set(time, @options[:lat], @options[:long]).localtime

      set += 86400 if set < rise
      set -= 86400 if set - rise > 86400

      if time >= rise && time <= set
        # beta chosen by rough experimentation such that the annual output curve roughly matches
        # the values from https://pvwatts.nrel.gov/pvwatts.php
        beta = 4
        offset = 1.05
        day_p = (time.to_i - rise.to_i) / (set.to_i - rise.to_i).to_f
        dv = beta_pdf(day_p, beta * offset, beta)
        dm = beta_pdf(0.5 * offset, beta * offset, beta)
        pct = dv / dm * 0.85 * (REL_MONTH_EFF[time.month] / OBS_MONTH_EFF[time.month].to_f).to_f
        # @logger.debug [rise, time, set, day_p]
        # Linear interpolation of efficiency up to the full-strength window
        offset = system_size * pct
      end
      kwh - offset
    end
  end
end
