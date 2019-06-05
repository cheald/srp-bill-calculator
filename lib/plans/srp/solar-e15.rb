module Plans
  module SRP
    class SolarAverage < Plans::SolarBase
      def self.solar_eligible
        true
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

      def demand_usage(date, hour, kwh)
        return 0 if level(date, hour) == 0
        if @demand_schedule
          demand_for_period(date)
        else
          # SRP demand charges are based on half-hour demand. We only have kWh to work with.
          # We'll estimate the half-hour peak charge as 75% of the total usage of the hour.
          # This likely undershoots a bit.
          kwh * 0.75
        end
      end

      def demand_rate(date, hour)
        case date.month
        when 1..4, 11..12
          8.13
        when 5..6, 9..10
          19.29
        else
          21.94
        end
      end

      def demand_for_period(date)
        key = date.strftime("%Y-%m")
        demand = (@demand_by_month[key] || [0])
        demand.inject(&:+) / demand.length.to_f
      end

      def level(date, hour)
        return 0 if holiday?(date)
        case date.month
        when 1..4, 11..12
          case hour
          when 5...9, 17...21
            1
          else
            0
          end
        else
          case hour
          when 14...20
            1
          else
            0
          end
        end
      end

      def rate(date, hour)
        l = level date, hour
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
