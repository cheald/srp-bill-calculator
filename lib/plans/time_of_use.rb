module Plans
  class TimeOfUse < Base
    def level(date, hour)
      case date.wday
      when 0, 6
        0
      else
        case date.month
        when 1..4, 11..12
          case hour
          when 5...9, 17...21
            1
          else
            0
          end
        else
          case hour
          when 13...20
            1
          else
            0
          end
        end
      end
    end

    def rate(date, hour)
      l = level date, hour
      case date.month
      when 1..4, 11..12
        case l
        when 0
          0.0711
        when 1
          0.1020
        end
      when 5..6, 9..10
        case l
        when 0
          0.0727
        when 1
          0.1946
        end
      when 7..8
        case l
        when 0
          0.0730
        when 1
          0.2215
        end
      end
    end
  end
end