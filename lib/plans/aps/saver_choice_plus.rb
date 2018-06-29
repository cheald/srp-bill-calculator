module Plans
  module APS
    class SaverChoicePlus < Base
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

      def demand_rate(date, hour)
        8.40
      end

      def level(date, hour)
        case date.wday
        when 0, 6
          0
        else
          case hour
          when 15...20
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
