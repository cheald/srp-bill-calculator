module Plans
  module SRP
    class ElectricVehicle < Base
      def notes
        "Only available to customers with a plug-in battery or hybrid vehicle."
      end

      def display_name
        "SRP/E29 (Electric Vehicle)"
      end

      def fixed_charges
        20
      end

      def level(date, hour)
        return 0 if holiday?(date)
        case date.month
        # Winter
        when 1..4, 11..12
          case hour
          when 0...5, 23..24
            0
          when 5...9, 17...21
            date.wday == 0 || date.wday == 6 ? 1 : 2
          else
            1
          end
        else
          case hour
          when 0...5, 23..24
            0
          when 14...20
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
            0.0575
          when 1
            0.0737
          when 2
            0.0951
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0611
          when 1
            0.0765
          when 2
            0.2094
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0614
          when 1
            0.0770
          when 2
            0.2409
          else
            raise "Bad level"
          end
        end
      end
    end
  end
end
