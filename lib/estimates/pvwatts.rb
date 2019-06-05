class PvwattsEstimate
  def initialize(file, system_size)
    @file = file
    @system_size = system_size
    generate_pvwatts_data
  end

  def estimate(date, time)
    key = date.strftime("%-m-%-d-%-H")
    @data[key] / @size * @system_size
  end

  private

  def generate_pvwatts_data
    f = File.read(@file)
    lines = []
    found = false
    size = 0
    f.lines.each do |l|
      if m = l.match(/DC System Size.*([\d.]+)/)
        size = m[1].to_f * 1000.0
      end
      found = true if l.match(/^"Month/)
      lines << l if found && !l.match(/^"Totals/)
    end

    data = {}
    CSV.parse(lines.join, headers: true).each do |row|
      data["%d-%d-%d" % [row["Month"], row["Day"], row["Hour"]]] = row["AC System Output (W)"].to_f
    end
    @size = size
    @data = data
  end
end
