module Plans
  module APS
    class SaverChoiceMax < Base
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
        case date.month
        when 5..10
          17.438
        else
          12.239
        end
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
            0.06376
          when 1
            0.05230
          end
        else
          case l
          when 0
            0.05230
          when 1
            0.08683
          end
        end
      end
    end
  end
end
