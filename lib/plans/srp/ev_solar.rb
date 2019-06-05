module Plans
  module SRP
    class EVSolar < SolarBase
      def demand_usage(date, kwh)
        0
      end

      def notes
        "Only available to customers with a plug-in battery or hybrid vehicle. Requires solar. " +
        "Estimated system cost: #{system_cost}."
      end

      def display_name
        "SRP/E14 (EV Solar)"
      end

      def fixed_charges
        32.44
      end

      def level(date)
        return :off_peak if holiday?(date)
        case date.month
        # Winter
        when 1..4, 11..12
          case date.hour
          when 0...5, 23..24
            :super_off_peak
          when 5...9, 17...21
            (date.wday == 0 || date.wday == 6) ? :off_peak : :on_peak
          else
            :off_peak
          end
        else
          case date.hour
          when 0...5, 23..24
            :super_off_peak
          when 14...20
            :on_peak
          else
            :off_peak
          end
        end
      end

      def net_metering_rate
        0.0281
      end

      def rate(date)
        l = level date
        case date.month
        when 1..4, 11..12
          case l
          when :super_off_peak
            0.0575
          when :off_peak
            0.0737
          when :on_peak
            0.0951
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when :super_off_peak
            0.0611
          when :off_peak
            0.0765
          when :on_peak
            0.2094
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when :super_off_peak
            0.0614
          when :off_peak
            0.0770
          when :on_peak
            0.2409
          else
            raise "Bad level"
          end
        end
      end
    end
  end
end
