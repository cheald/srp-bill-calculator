module Plans
  module SRP
    class Solar < Plans::SolarBase
      include ::SRP::Dates

      def display_name
        "SRP/E27 (Customer Generation)"
      end

      def notes
        n = "Estimated system cost: #{system_cost}."
        n += " Demand charges are estimated and may be inaccurate." unless @demand_schedule
        n
      end

      def fixed_charges
        32.44
      end

      def demand_usage(date, kwh)
        return 0 if level(date) == :off_peak
        if @demand_schedule
          demand_for_period(date)
        else
          # SRP cares about half-hour demand, but it doesn't particularly define this; I think this means effectively
          # the peak kilowatt-half hour for the month. We'll use 15% over the peak value of any individual hour, to
          # estimate cases where peak draw was high for a period, and was then dropped for the remainder of the hour.
          kwh * 1.15
        end
      end

      # Only accumulate demand charges for on-peak periods
      def add_demand(date, kwh)
        return 0 unless level(date) != :off_peak

        if kwh > 20
          p [kwh, date, level(date)]
        end

        super
      end

      def demand_cost(demand, date)
        a = b = c = nil

        case season(date)
        when :winter
          a = 3.49
          b = 5.58
          c = 9.57
        when :summer
          a = 7.89
          b = 14.37
          c = 27.28
        else
          a = 9.43
          b = 17.51
          c = 33.59
        end

        peak_demand = demand_for_period(date) || 0
        return 0 if peak_demand == 0

        if peak_demand > 10
          ((a * 3) + (b * 7) + (c * (peak_demand - 10)))
        elsif peak_demand > 3
          ((a * 3) + (b * (peak_demand - 3)))
        else
          a
        end
      end

      def level(date)
        return :off_peak if holiday?(date)
        case season(date)
        when :winter
          case date.hour
          when 5...9, 17...21
            :on_peak
          else
            :off_peak
          end
        else
          case date.hour
          when 14...20
            :on_peak
          else
            :off_peak
          end
        end
      end

      def rate(date)
        l = level date
        case season(date)
        when :winter
          case l
          when :off_peak
            0.0370
          when :on_peak
            0.0410
          else
            raise "Bad level"
          end
        when :summer
          case l
          when :off_peak
            0.0360
          when :on_peak
            0.0462
          else
            raise "Bad level"
          end
        when :summer_peak
          case l
          when :off_peak
            0.0412
          when :on_peak
            0.0622
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
