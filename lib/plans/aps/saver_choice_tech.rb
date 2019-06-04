module Plans
  module APS
    class SaverChoiceTech < Base
      def self.solar_eligible
        true
      end

      def fixed_charges
        (0.493 * 30)
      end

      # APS uses average demand rather than peak demand
      def demand_for_period(date)
        key = date.strftime("%Y-%m")
        return 0 if @demand_by_month[key].length == 0
        @demand_by_month[key].inject(:+) / @demand_by_month[key].length.to_f
      end

      def demand_usage(date, hour, kwh)
        case date.wday
        when 1..5
          case hour
          when 15...20
            kwh
          else
            0
          end
        else
          0
        end
      end

      def level(date, hour)
        case date.wday
        when 0, 6
          1
        else
          case date.month
          when 1..4, 11..12
            case hour
            when 10...15
              0
            when 15...20
              2
            else
              1
            end
          else
            case hour
            when 15...20
              2
            else
              1
            end
          end
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.032
          when 1
            0.10873
          when 2
            0.23068
          end
        else
          case l
          when 1
            0.10873
          when 2
            0.24314
          end
        end
      end
    end
  end
end
