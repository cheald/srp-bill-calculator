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
          0.0782
        when :summer
          0.1114
        else
          0.1185
        end
      end
    end
  end
end
