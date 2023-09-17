# frozen_string_literal: true

require "formula"
require "formulary"
require "simulate_system"
require "tap"

# Expects:
# 1. Temporary directory that exists
# 2. Command type from VALID_COMMAND_TYPES
# 3. Command arg
#    - for command type `tap` it should be the name of a tap
#    - for command type `formula` it should be the name of a formula
#    - for command type `all` it is NOT necessary
TMP_DIR, COMMAND_TYPE, COMMAND_ARG, *extra = ARGV

VALID_COMMAND_TYPES = %w[all tap formula].freeze

if !Dir.exist?(TMP_DIR)
  odie "Temporary directory `#{TMP_DIR}` does not exist!"
elsif !VALID_COMMAND_TYPES.include?(COMMAND_TYPE)
  odie "Unknown command type `#{COMMAND_TYPE}`!"
elsif COMMAND_TYPE == "all" && COMMAND_ARG
  odie "Unexpected command arg `#{COMMAND_ARG}` for `all` command!"
elsif extra.any?
  odie "Unexpected additional arguments `#{extra}`!"
end

formula_files =
  case COMMAND_TYPE
  when "all"
    Formula.all(eval_all: true)
  when "tap"
    Tap.fetch(COMMAND_ARG).formula_files.map(&Formulary.method(:factory))
  when "formula"
    [Formulary.factory(COMMAND_ARG)]
  end
  .select { |f| f.service? || f.plist }
  .map(&:path)

if formula_files.empty?
  odie "No formulae with service blocks to compare according to the given criteria!"
end

MACOS_DIR = Pathname(TMP_DIR)/"macos"
MACOS_DIR.mkdir

Homebrew::SimulateSystem.with(os: :macos) do
  formula_files.each do |formula_file|
    formula = Formulary.factory(formula_file)

    service_content =
      if formula.service.command?
        formula.service.to_plist
      elsif formula.plist
        formula.plist
      end

    next if service_content.nil?

    outfile = MACOS_DIR/"#{formula.plist_name}.plist"
    File.write(outfile, service_content)
  end
end

LINUX_DIR = Pathname(TMP_DIR)/"linux"
LINUX_DIR.mkdir

Homebrew::SimulateSystem.with(os: :linux) do
  formula_files.each do |formula_file|
    formula = Formulary.factory(formula_file)

    if formula.service? && formula.service.command?
      outfile = LINUX_DIR/"#{formula.service_name}.service"
      File.write(outfile, formula.service.to_systemd_unit)

      if formula.service.timed?
        outfile = LINUX_DIR/"#{formula.service_name}.timer"
        File.write(outfile, formula.service.to_systemd_timer)
      end
    end
  end
end
