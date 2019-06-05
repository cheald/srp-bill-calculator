module Plans
  module SRP
    class TimeOfUseSolar < SolarBase
      include ::SRP::Dates

      def fixed_charges
        32.44
      end

      def display_name
        "SRP/E13 (TOU Solar)"
      end

      def notes
        "Estimated system cost: #{system_cost}."
      end

      def demand_usage(date, kwh)
        0
      end

      def net_metering_rate
        0.0281
      end

      def level(date)
        standard_level date
      end

      def rate(date)
        l = level date
        case season(date)
        when :winter
          case l
          when :off_peak
            0.0691
          when :on_peak
            0.0951
          else
            raise "Bad level"
          end
        when :summer
          case l
          when :off_peak
            0.0727
          when :on_peak
            0.2094
          else
            raise "Bad level"
          end
        when :summer_peak
          case l
          when :off_peak
            0.0730
          when :on_peak
            0.2409
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
