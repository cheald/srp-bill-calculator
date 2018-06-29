require 'csv'
require 'time'
require_relative "./lib/plans"

ez3 = Plans::EZThree.new
ev = Plans::EV.new
tou = Plans::TimeOfUse.new
bas = Plans::Basic.new

CSV.open(ARGV[0], headers: true) do |csv|
  csv.each do |row|
    puts ""
    ez3.add(row[0], row[1], row[2])
    ev.add(row[0], row[1], row[2])
    tou.add(row[0], row[1], row[2])
    bas.add(row[0], row[1], row[2])
  end
end

puts ez3
puts ev
puts tou
puts bas