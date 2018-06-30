module Plans
  module APS
    class PremierChoice < Base
      def notes
        "Only applies if you use fewer than 1000 kWh monthly. Your average monthly usage is #{format "%2.0f", total_kwh / billing_periods.to_f} kWh."
      end

      def fixed_charges
        13
      end

      def rate(date, hour)
        0.12393
      end
    end
  end
end
