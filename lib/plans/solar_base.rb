require_relative "../sun_times"

module Plans
  class SolarBase < ::Plans::Base
    EFF_BY_MO = [0, 4.4, 5.4, 6.4, 7.5, 8.0, 8.1, 7.5, 7.3, 6.8, 6.0, 4.9, 4.2]
    EFF_BY_MO_MAX = EFF_BY_MO.max.to_f
    COST_PER_WATT_INSTALLED = 3.52

    def offset(date, time, kwh)
      offset = 0
      system_size = @options.fetch(:offset, 0).to_f
      month_modifier = EFF_BY_MO[date.month] / EFF_BY_MO_MAX

      efficiency = 0.78
      system_size *= efficiency

      rise = SunTimes.new.rise(time, @options[:lat], @options[:long]).localtime
      set = SunTimes.new.set(time, @options[:lat], @options[:long]).localtime
      set += 86400 if set < rise
      set -= 86400 if set - rise > 86400

      full_strength_window = 3.5 * 3600
      if time >= rise + full_strength_window && time <= set - full_strength_window
        offset = system_size * month_modifier
      elsif time >= rise && time <= set
        # Linear interpolation of efficiency up to the full-strength window
        percent = ([time - rise, set - time].min / 3600.0) / (full_strength_window / 3600).to_f
        offset = system_size * month_modifier * percent
      end
      kwh - offset
    end
  end
end
