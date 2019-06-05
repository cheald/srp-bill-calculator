module SRP
  module Dates
    def season(date)
      return :winter if winter?(date)
      return :summer if summer?(date)
      return :summer_peak if summer_peak?(date)
      raise "Bad date!"
    end

    def winter?(date)
      (1..4).cover?(date.month) ||
      (11..12).cover?(date.month)
    end

    def summer?(date)
      (5..6).cover?(date.month) || (9..10).cover?(date.month)
    end

    def summer_peak?(date)
      (7..8).cover?(date.month) || (9..10).cover?(date.month)
    end

    def standard_level(date)
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

    def super_offpeak_level(date)
      return :off_peak if holiday?(date)
      case season(date)
      when :winter
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
  end
end
