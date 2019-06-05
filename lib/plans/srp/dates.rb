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
  end
end
