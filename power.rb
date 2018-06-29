require 'csv'
require 'time'
require "optparse"
require 'logger'
require_relative "./lib/plans"

logger = Logger.new $stderr

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-d", "--debug", "Print debug information") do |v|
    options[:debug] = v
  end

  opts.on("-f", "--file csv", "CSV to parse") do |v|
    options[:csv] = v
  end
end.parse!

if options[:debug]
  logger.level = Logger::DEBUG
else
  logger.level = Logger::INFO
end

plans = [
  Plans::EZThree.new(logger),
  Plans::EV.new(logger),
  Plans::TimeOfUse.new(logger),
  Plans::Basic.new(logger),
]

logger.info "Computing..."

CSV.open(options[:csv], headers: true) do |csv|
  csv.each do |row|
    logger.debug "-" * 73
    plans.each {|plan| plan.add(row[0], row[1], row[2]) }
  end
end

def colorize_string(string, code)
  "\e[0;#{code};49m#{string}\e[0m"
end

sorted = plans.sort_by(&:total)
best = sorted.shift
worst = sorted.pop

puts colorize_string best, 32
sorted.each do |plan|
  puts colorize_string plan, 33
end
puts colorize_string worst, 31