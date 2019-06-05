module Plans
  module APS
    class PremierChoiceLarge < Base
      def notes
      end

      def fixed_charges
        0.658 * 30
      end

      def rate(date)
        0.13412
      end
    end
  end
end
