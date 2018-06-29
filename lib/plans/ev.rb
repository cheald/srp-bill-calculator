module Plans
  class ElectricVehicle < Base
    def level(date, hour)
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