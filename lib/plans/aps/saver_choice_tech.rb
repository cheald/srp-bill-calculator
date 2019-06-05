module Plans
  module APS
    class SaverChoiceTech < Base
      include AverageDemandConcern

      def self.solar_eligible
        true
      end

      def fixed_charges
        (0.493 * 30)
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

      def level(date)
        case date.wday
        when 0, 6
          1
        else
          case date.month
          when 1..4, 11..12
            case date.hour
            when 10...15
              0
            when 15...20
              2
            else
              1
            end
          else
            case date.hour
            when 15...20
              2
            else
              1
            end
          end
        end
      end

      def rate(date)
        l = level date
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
