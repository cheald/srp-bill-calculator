module Plans
  module SRP
    class SolarAverage < Plans::SolarBase
      include AverageDemandConcern

      # Only accumulate demand charges for on-peak periods
      def add_demand(date, kwh)
        return 0 unless level(date) > 0
        super
      end

      def display_name
        "SRP/E15 (Average Demand)"
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
        return 0 if level(date) == 0
        if @demand_schedule
          demand_for_period(date)
        else
          # SRP cares about half-hour demand, but it doesn't particularly define this; I think this means effectively
          # the peak kilowatt-half hour for the month. We'll use 15% over the peak value of any individual hour, to
          # estimate cases where peak draw was high for a period, and was then dropped for the remainder of the hour.
          kwh * 1.15
        end
      end

      def demand_rate(date)
        case date.month
        when 1..4, 11..12
          8.13
        when 5..6, 9..10
          19.29
        else
          21.94
        end
      end

      def level(date)
        return 0 if holiday?(date)
        case date.month
        when 1..4, 11..12
          case date.hour
          when 5...9, 17...21
            1
          else
            0
          end
        else
          case date.hour
          when 14...20
            1
          else
            0
          end
        end
      end

      def rate(date)
        l = level date
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.0370
          when 1
            0.0410
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0360
          when 1
            0.0462
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0412
          when 1
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
