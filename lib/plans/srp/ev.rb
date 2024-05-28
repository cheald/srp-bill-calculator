module Plans
  module SRP
    class ElectricVehicle < Base
      include ::SRP::Dates

      def notes
        "Only available to customers with a plug-in battery or hybrid vehicle."
      end

      def display_name
        "SRP/E29 (Electric Vehicle)"
      end

      def fixed_charges
        20
      end

      def level(date)
        super_offpeak_level date
      end

      def rate(date)
        l = level date
        case season(date)
        when :winter
          case l
          when :super_off_peak
            0.0769
          when :off_peak
            0.0931
          when :on_peak
            0.1145
          else
            raise "Bad level"
          end
        when :summer
          case l
          when :super_off_peak
            0.0787
          when :off_peak
            0.0941
          when :on_peak
            0.2270
          else
            raise "Bad level"
          end
        when :summer_peak
          case l
          when :super_off_peak
            0.0790
          when :off_peak
            0.0946
          when :on_peak
            0.2585
          else
            raise "Bad level"
          end
        end
      end
    end
  end
end
