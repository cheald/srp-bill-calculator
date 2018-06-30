module Plans
  module APS
    class LiteChoice < Base
      def notes
        "Only applies if you use fewer than 600 kWh monthly. Your average monthly usage is #{format "%2.0f", total_kwh / billing_periods.to_f} kWh."
      end

      def fixed_charges
        10
      end

      def rate(date, hour)
        0.11672
      end
    end
  end
end
