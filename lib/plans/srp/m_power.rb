module Plans
  module SRP
    class MPower < Base
      include ::SRP::Dates
      # I _think_ that MPower doesn't assess a separate service charge. I'd like to double check this.
      def fixed_charges
        20.0
      end

      def rate(date)
        case season(date)
        when :winter
          0.0976
        when :summer
          0.1290
        when :summer_peak
          0.1361
        else
          raise "bad rate"
        end
      end
    end
  end
end
