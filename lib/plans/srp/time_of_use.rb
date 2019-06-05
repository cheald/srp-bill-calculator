module Plans
  module SRP
    class TimeOfUse < Base
      def fixed_charges
        20
      end

      def level(date)
        return 0 if holiday?(date)
        case date.wday
        when 0, 6
          0
        else
          case date.month
          when 1..4, 11..12
            case date.hour
            when 5...9, 17...21
              1
            else
              0
            end
          else
            case date.hour
            when 14...20
              1
            else
              0
            end
          end
        end
      end

      def rate(date)
        l = level date
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.0691
          when 1
            0.0951
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0727
          when 1
            0.2094
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0730
          when 1
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
