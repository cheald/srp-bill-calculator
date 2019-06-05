module Plans
  module SRP
    class EZThree < Base
      def fixed_charges
        20
      end

      def level(date, hour)
        return 0 if holiday?(date)
        case date.wday
        when 0, 6
          0
        else
          start = @options.fetch(:srp_ez3_start_hour, "15").to_i
          (start...start + 3).cover?(hour) ? 1 : 0
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.0738
          when 1
            0.1063
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0829
          when 1
            0.2895
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0853
          when 1
            0.3444
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
