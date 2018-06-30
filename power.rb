require "csv"
require "time"
require "optparse"
require "logger"
require_relative "./lib/plans"

logger = Logger.new $stderr

options = {provider: "srp"}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-d", "--debug", "Print debug information") do |v|
    options[:debug] = v
  end

  opts.on("-f", "--file csv", "CSV to parse") do |v|
    options[:csv] = v
  end

  opts.on("-p", "--provider (aps|srp)", "Electric provider's rate plans to use") do |v|
    options[:provider] = v
  end

  opts.on("-m", "--demand csv", "Provide an additional demand CSV, available to customers on the SRP E27 plan") do |v|
    options[:demand_schedule] = v
  end
end.parse!

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

plans = root.constants.map { |c| root.const_get(c).new(logger, demand_schedule) }

CSV.open(options[:csv], headers: true) do |csv|
  arr = csv.to_a
  arr.each do |row|
    row[0] = Date.strptime(row[0], "%m/%d/%Y") rescue nil
  end
  arr.select(&:first).sort_by(&:first).each do |row|
    logger.debug "-" * 79
    plans.each { |plan| plan.add(row[0], row[1], row[2]) }
  end
end

def colorize_string(string, code)
  "\e[0;#{code};49m#{string}\e[0m"
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
