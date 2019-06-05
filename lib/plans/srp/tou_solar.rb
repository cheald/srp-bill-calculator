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
        return :off_peak if holiday?(date)
        case date.wday
        when 0, 6
          :off_peak
        else
          case season(date)
          when :winter
            case date.hour
            when 5...9, 17...21
              :on_peak
            else
              :off_peak
            end
          else
            case date.hour
            when 14...20
              :on_peak
            else
              :off_peak
            end
          end
        end
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
