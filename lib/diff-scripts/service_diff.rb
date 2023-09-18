# frozen_string_literal: true

require "formula"
require "formulary"
require "simulate_system"
require "tap"

# Expects:
# 1. Command type from VALID_COMMAND_TYPES
# 2. Command arg
#    - for command type `tap` it should be the name of a tap
#    - for command type `formula` it should be the name of a formula
#    - for command type `all` it is NOT necessary
COMMAND_TYPE, COMMAND_ARG, *extra = ARGV

VALID_COMMAND_TYPES = %w[all tap formula].freeze

if VALID_COMMAND_TYPES.exclude?(COMMAND_TYPE)
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

odie "No formulae with service blocks to compare according to the given criteria!" if formula_files.empty?

MACOS_DIR = Pathname("macos").expand_path.freeze
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

LINUX_DIR = Pathname("linux").expand_path.freeze
LINUX_DIR.mkdir

Homebrew::SimulateSystem.with(os: :linux) do
  formula_files.each do |formula_file|
    formula = Formulary.factory(formula_file)

    next unless formula.service? && formula.service.command?

    outfile = LINUX_DIR/"#{formula.service_name}.service"
    File.write(outfile, formula.service.to_systemd_unit)

    if formula.service.timed?
      outfile = LINUX_DIR/"#{formula.service_name}.timer"
      File.write(outfile, formula.service.to_systemd_timer)
    end
  end
end
