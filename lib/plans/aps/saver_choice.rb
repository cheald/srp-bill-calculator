module Plans
  module APS
    class SaverChoice < Base
      def fixed_charges
        13
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
