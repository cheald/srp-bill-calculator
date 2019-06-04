module Plans
  module SRP
    class EVSolar < SolarBase
      def self.solar_eligible
        true
      end

      def demand_usage(date, hour, kwh)
        0
      end

      def notes
        "Only available to customers with a plug-in battery or hybrid vehicle. Requires solar. " +
        "Estimated system cost: $#{format "%2.0f", COST_PER_WATT_INSTALLED * @options.fetch(:offset, 0).to_f * 1000.0}."
      end

      def display_name
        "SRP/E14"
      end

      def fixed_charges
        32.44
      end

      def level(date, hour)
        return 0 if holiday?(date)
        case date.wday
        when 0, 6
          case hour
          when 0...5, 23..24
            0
          else
            1
          end
        else
          case hour
          when 0...5, 23..24
            0
          when 5...9, 17...21
            2
          else
            1
          end
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.06
          when 1
            0.0757
          when 2
            0.1020
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0616
          when 1
            0.0765
          when 2
            0.1946
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0619
          when 1
            0.0770
          when 2
            0.2215
          else
            raise "Bad level"
          end
        end
      end
    end
  end
end
