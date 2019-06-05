require_relative "./sun_times"

module SolarEstimate
  REL_MONTH_EFF = [0, 916, 918, 1185, 1330, 1358, 1305, 1222, 1209, 1128, 1099, 939, 861]
  OBS_MONTH_EFF = [0, 852, 947, 1142, 1185, 1324, 1447, 1298, 1268, 1136, 1076, 960, 950]

  def self.estimate(date, time, system_size, efficiency, lat, long)
    offset = 0
    system_size *= efficiency

    rise = SunTimes.new.rise(time, lat, long).localtime
    set = SunTimes.new.set(time, lat, long).localtime

    set += 86400 if set < rise
    set -= 86400 if set - rise > 86400

    if time >= rise && time <= set
      # beta chosen by rough experimentation such that the annual output curve roughly matches
      # the values from https://pvwatts.nrel.gov/pvwatts.php
      beta = 4
      offset = 1.05
      day_p = (time.to_i - rise.to_i) / (set.to_i - rise.to_i).to_f
      dv = beta_pdf(day_p, beta * offset, beta)
      dm = beta_pdf(0.5 * offset, beta * offset, beta)
      pct = dv / dm * 0.85 * (REL_MONTH_EFF[time.month] / OBS_MONTH_EFF[time.month].to_f).to_f
      # @logger.debug [rise, time, set, day_p]
      # Linear interpolation of efficiency up to the full-strength window
      offset = system_size * pct
    end
    offset
  end

  def self.beta_pdf(x, a, b)
    return 0 if x < 0 || x > 1

    gab = Math.lgamma(a + b).first
    ga = Math.lgamma(a).first
    gb = Math.lgamma(b).first

    if x == 0.0 || x == 1.0
      Math.exp(gab - ga - gb) * x ** (a - 1) * (1 - x) ** (b - 1)
    else
      Math.exp(gab - ga - gb + Math.log(x) * (a - 1) + log1p(-x) * (b - 1))
    end
  end

  def self.log1p(x)
    y = 1 + x
    Math.log(y) - ((y - 1) - x).quo(y) # cancel errors with IEEE arithmetic
  end
end
