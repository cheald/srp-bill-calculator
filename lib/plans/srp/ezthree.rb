module Plans
  module SRP
    class EZThree < Base
      include ::SRP::Dates

      def fixed_charges
        20
      end

      def level(date)
        return :off_peak if holiday?(date)
        case date.wday
        when 0, 6
          :off_peak
        else
          start = @options.fetch(:srp_ez3_start_hour, "15").to_i
          (start...start + 3).cover?(date.hour) ? :on_peak : :off_peak
        end
      end

      def rate(date)
        l = level date
        case season(date)
        when :winter
          case l
          when :off_peak
            0.0738
          when :on_peak
            0.1063
          else
            raise "Bad level"
          end
        when :summer
          case l
          when :off_peak
            0.0829
          when :on_peak
            0.2895
          else
            raise "Bad level"
          end
        when :summer_peak
          case l
          when :off_peak
            0.0853
          when :on_peak
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
