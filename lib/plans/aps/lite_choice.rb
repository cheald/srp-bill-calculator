module Plans
  module APS
    class LiteChoice < Base
      def notes
        avg = @usage_by_month.values.inject(:+) / @usage_by_month.length
        min = @usage_by_month.values.min
        max = @usage_by_month.values.max

        "Only applies if you use fewer than 0600 kWh monthly. " +
        "You average #{format "%2.0f", avg} kWh/mo (#{format "%2.0f", min} min, #{format "%2.0f", max} max)."
      end

      def fixed_charges
        10
      end

      def rate(date)
        0.11672
      end
    end
  end
end
