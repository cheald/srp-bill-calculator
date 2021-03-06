module Plans
  module APS
    class SaverChoicePlus < Base
      include AverageDemandConcern

      def self.solar_eligible
        true
      end

      def fixed_charges
        13
      end

      def demand_usage(date, kwh)
        case date.wday
        when 1..5
          case date.hour
          when 15...20
            kwh
          else
            0
          end
        else
          0
        end
      end

      def demand_rate(date)
        8.40
      end

      def level(date)
        case date.wday
        when 0, 6
          0
        else
          case date.hour
          when 15...20
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
            0.07798
          when 1
            0.11017
          end
        else
          case l
          when 0
            0.07798
          when 1
            0.13160
          end
        end
      end
    end
  end
end
