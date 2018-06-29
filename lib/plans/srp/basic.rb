module Plans
  module SRP
    class Basic < Base
      def level(date, hour)
        case date.month
        when 1..4, 11..12
          0
        when 5..6, 9..10
          if monthly_usage <= 700
            0
          elsif monthly_usage <= 2000
            1
          else
            2
          end
        when 7..8
          if monthly_usage <= 700
            0
          elsif monthly_usage <= 2000
            1
          else
            2
          end
        else
          raise "Bad level"
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          0.083
        when 5..6, 9..10
          case l
          when 0
            0.1091
          when 1
            0.1110
          when 2
            0.1215
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.1157
          when 1
            0.1169
          when 2
            0.1320
          else
            raise "Bad level"
          end
        end
      end
    end
  end
end
