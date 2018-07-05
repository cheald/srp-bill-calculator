require "csv"
require "time"
require "awesome_print"

dates = {}
CSV.open(ARGV[0], headers: false) do |f|
  f.each.with_index do |line, index|
    next if index < 2
    d = Date.strptime line[0], "%m/%d/%Y"
    t = Time.parse line[1]
    r = line[2].to_f
    key = format("%d:%d", d.yday, t.hour)
    dates[d.yday] ||= {}
    dates[d.yday][t.hour] = r
  end
end

CSV.open(ARGV[1], "w") do |f|
  dates.each do |yday, hours|
    f << [yday] + hours.sort_by { |k, v| k }.map(&:last)
  end
end
