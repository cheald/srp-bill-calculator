module Plans
  class Base
    def initialize
      @total = 0
    end

    def add(date, hour, kwh)
      v = cost date, hour, kwh
      puts format("%20s %15s %-15s %2.2f kWh costs $%2.2f", self.class.to_s, date, hour, kwh, v)
      @total += v
    end

    def cost(date, hour, kwh)
      date = Date.strptime date, "%m/%d/%Y"
      kwh = kwh.to_f
      hour = Time.parse(hour).hour
      rate(date, hour) * kwh.to_f
    end

    def to_s
      format "%-20s\t$%2.2f", self.class.to_s, @total
    end
  end
end