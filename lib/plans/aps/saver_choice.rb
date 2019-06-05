module Plans
  module APS
    class SaverChoice < Base
      def self.solar_eligible
        true
      end

      def fixed_charges
        system_size = @options.fetch(:offset, 0).to_f
        13 + 0.93 * system_size
      end

      def level(date)
        case date.wday
        when 0, 6
          1
        else
          case date.month
          when 1..4, 11..12
            case date.hour
            when 10...15
              0
            when 15...20
              2
            else
              1
            end
          else
            case date.hour
            when 15...20
              2
            else
              1
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
            0.032
          when 1
            0.10873
          when 2
            0.23068
          end
        else
          case l
          when 1
            0.10873
          when 2
            0.24314
          end
        end
      end
    end
  end
end
