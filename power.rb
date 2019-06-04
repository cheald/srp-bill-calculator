require "csv"
require "time"
require "optparse"
require "logger"
require_relative "./lib/plans"

def colorize_string(string, code)
  "\e[0;#{code};49m#{string}\e[0m"
end

logger = Logger.new $stderr
# default lat/long are for Phoenix in general
options = { provider: "srp", lat: 33.448376, long: -112.074036, cpw: 3.52, efficiency: 0.78 }

parser = OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-d", "--debug", "Print debug information") do |v|
    options[:debug] = v
  end

  opts.on("-f", "--file CSV", "CSV to parse") do |v|
    options[:csv] = v
  end

  opts.on("-p", "--provider (aps|srp)", "Electric provider's rate plans to use") do |v|
    options[:provider] = v
  end

  opts.on("-m", "--demand CSV", "Provide an additional demand CSV, available to customers on the SRP E27 plan") do |v|
    options[:demand_schedule] = v
  end

  opts.on("-o", "--offset kwh", "Estimate an offset of this many kWh from a solar system") do |v|
    options[:offset] = v.to_f
  end

  opts.on("--srp-ez3-start-hour [14,15,16]", %w(14 15 16), "Specify the starting hour as 24h time for SRP's EZ3 plan, for legacy customers.") do |v|
    options[:srp_ez3_start_hour] = v.to_i
  end

  opts.on("--location loc", "Specify your location as lat,long for accurate sunrise/sunset times") do |v|
    options[:lat], options[:long] = v.split(",").map(&:to_f)
  end

  opts.on("-w", "--costperwatt cpw", "Cost per watt (installed)") do |v|
    options[:cpw] = v.to_f
  end

  opts.on("-e", "--efficiency efficiency", "Array efficiency vs nominal (0.78 default)") do |v|
    options[:efficiency] = v.to_f
  end
end

begin
  parser.parse!
rescue OptionParser::InvalidArgument => e
  puts colorize_string "Invalid option: #{e.message}", 31
  puts ""
  puts parser.help
  puts ""
  exit
end

if options[:csv].nil?
  puts colorize_string "Missing data file! Pass your CSV with the -f option.", 31
  puts ""
  puts parser.help
  exit
end

if options[:debug]
  logger.level = Logger::DEBUG
else
  logger.level = Logger::INFO
end

root = case options[:provider]
       when "srp"
         Plans::SRP
       else
         Plans::APS
       end

demand_schedule = nil
if options[:demand_schedule]
  demand_schedule = {}
  CSV.open(options[:demand_schedule], headers: true).each do |row|
    key = Date.strptime(row[0], "%m/%d/%Y").strftime("%Y-%m")
    demand = row[2].to_f
    demand_schedule[key] ||= demand
    demand_schedule[key] = demand if demand > demand_schedule[key]
  end
end

plans = root::PLANS.select { |c| !options[:offset] || c.solar_eligible }.map { |c| c.new(logger, demand_schedule, options) }
plans = root::PLANS.map { |c| c.new(logger, demand_schedule, options) }

CSV.open(options[:csv], headers: true) do |csv|
  arr = csv.to_a
  arr.each do |row|
    row[0] = Date.strptime(row[0], "%m/%d/%Y") rescue nil
  end
  arr.select(&:first).sort_by(&:first).each do |row|
    logger.debug "-" * 79
    date = row[0]
    time = Time.parse(row[1])
    datetime = Time.local(date.year, date.month, date.day, time.hour, time.min, time.sec)
    plans.each { |plan| plan.add(datetime, row[2].to_f) }
  end
end

sorted = plans.sort_by(&:total)
best = sorted.shift
worst = sorted.pop

puts <<-EOF

NOTE: The following projections include fixed fees (such as monthly service charges)
and energy costs, but do not include taxes or extra costs such as SRP Earthwise. These
projections may not match your actual bill as a result, but should accurately reflect
the relative cost of the programs.

EOF

Plans::Base.print_header
puts colorize_string best, 32
sorted.each do |plan|
  puts colorize_string plan, 33
end
puts colorize_string worst, 31 if worst
puts ""
