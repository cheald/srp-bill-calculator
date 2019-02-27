module Plans
  module SRP
    class Solar < Base
      # We use this to estimate array efficiency by month
      # https://rredc.nrel.gov/solar/pubs/redbook/PDFs/AZ.PDF
      EFF_BY_MO = [0, 4.4, 5.4, 6.4, 7.5, 8.0, 8.1, 7.5, 7.3, 6.8, 6.0, 4.9, 4.2]
      EFF_BY_MO_MAX = EFF_BY_MO.max.to_f

      def display_name
        "SRP::Customer Generation/E27"
      end

      def notes
        n = "Customers with PV arrays may only use this plan."
        n += " Demand charges are estimated and may be inaccurate." unless @demand_schedule
        n
      end

      def offset(date, hour, kwh)
        offset = 0
        system_size = @options.fetch(:offset, 0).to_f
        month_modifier = EFF_BY_MO[date.month] / EFF_BY_MO_MAX
        if hour.hour >= 9 && hour.hour <= 15
          # Peak hours are between 9 AM and 3 PM
          offset = system_size * month_modifier
        elsif hour.hour >= 7 && hour.hour < 18
          # Outside of peak hours, estimate only 60% efficiency
          offset = system_size * month_modifier * 0.6
        end
        [0, kwh - offset].max
      end

      def fixed_charges
        32.44
      end

      # SRP demand charges are based on half-hour demand. We only have kWh to work with.
      def demand_usage(date, hour, kwh)
        return 0 if level(date, hour) == 0
        if @demand_schedule
          demand_for_period(date.year, date.month)
        else
          kwh / 2.0
        end
      end

      def demand_rate(date, hour)
        a = nil
        b = nil
        c = nil
        case date.month
        when 1..4, 11..12
          a = 3.55
          b = 5.68
          c = 9.74
        when 5..6, 9..10
          a = 8.03
          b = 14.63
          c = 27.77
        else
          a = 9.59
          b = 17.82
          c = 34.19
        end

        peak_demand = demand_for_period(date.year, date.month)
        return 0 if peak_demand == 0

        if peak_demand > 10
          (a * 3) + (b * 7) + (c * (peak_demand - 10))
        elsif peak_demand > 3
          (a * 3) + (b * (peak_demand - 3))
        else
          a * peak_demand
        end
      end

      def level(date, hour)
        return 0 if holiday?(date)
        case date.wday
        when 0, 6
          0
        else
          (15..18).cover?(hour) ? 1 : 0
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.0758
          when 1
            0.01215
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0829
          when 1
            0.3022
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0853
          when 1
            0.3577
          else
            raise "Bad level"
          end
        else
          raise "Bad level"
        end
      end
    end
  end
end
