module Plans
  module SRP
    class Basic < Base
      def fixed_charges
        20
      end

      def level(date)
        case date.month
        when 1..4, 11..12
          :off_peak
        when 5..6, 9..10
          if monthly_usage <= 2000
            :off_peak
          else
            :on_peak
          end
        when 7..8
          if monthly_usage <= 2000
            :off_peak
          else
            :on_peak
          end
        else
          raise "Bad level"
        end
      end

      def rate(date)
        l = level date
        case date.month
        when 1..4, 11..12
          0.0782
        when 5..6, 9..10
          case l
          when :off_peak
            0.1091
          when :on_peak
            0.1134
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when :off_peak
            0.1157
          when :on_peak
            0.127
          else
            raise "Bad level"
          end
        end
      end
    end
  end
end
