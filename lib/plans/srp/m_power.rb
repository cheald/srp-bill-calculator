module Plans
  module SRP
    class MPower < Base
      def rate(date, hour)
        case date.month
        when 1..4, 11..12
          0.0942
        when 5..6, 9..10
          0.1089
        else
          0.1159
        end
      end
    end
  end
end
