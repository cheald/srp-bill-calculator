module Plans
  module SRP
    class Basic < Base
      def fixed_charges
        20
      end

      def level(date, hour)
        case date.month
        when 1..4, 11..12
          0
        when 5..6, 9..10
          if monthly_usage <= 2000
            0
          else
            1
          end
        when 7..8
          if monthly_usage <= 2000
            0
          else
            1
          end
        else
          raise "Bad level"
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          0.0782
        when 5..6, 9..10
          case l
          when 0
            0.1091
          when 1
            0.1134
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.1157
          when 1
            0.127
          else
            raise "Bad level"
          end
        end
      end
    end
  end
end
