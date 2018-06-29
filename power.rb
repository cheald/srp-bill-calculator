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
end.parse!

if options[:debug]
  logger.level = Logger::DEBUG
else
  logger.level = Logger::INFO
end

plans = case options[:provider]
        when "srp"
          [
            Plans::SRP::EZThree.new(logger),
            Plans::SRP::ElectricVehicle.new(logger),
            Plans::SRP::TimeOfUse.new(logger),
            Plans::SRP::Basic.new(logger),
            Plans::SRP::MPower.new(logger),
          # Plans::SRP::Solar.new(logger),
          ]
        else
          [
            Plans::APS::SaverChoice.new(logger),
            Plans::APS::SaverChoicePlus.new(logger),
            Plans::APS::SaverChoiceMax.new(logger),
          ]
        end

logger.info "Computing..."

CSV.open(options[:csv], headers: true) do |csv|
  csv.each do |row|
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

puts colorize_string best, 32
sorted.each do |plan|
  puts colorize_string plan, 33
end
puts colorize_string worst, 31 if worst
