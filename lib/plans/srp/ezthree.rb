module Plans
  module SRP
    class EZThree < Base
      def level(date, hour)
        case date.wday
        when 0, 6
          0
        else
          (15..18).cover?(hour) ? 1 : 0
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.0758
          when 1
            0.01215
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0829
          when 1
            0.3022
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0853
          when 1
            0.3577
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
