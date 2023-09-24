# frozen_string_literal: true

# NOTE: This file should be run with HOMEBREW_NO_INSTALL_FROM_API set.

require "formula"
require "formulary"
require "json"
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

FORMULAE =
  case COMMAND_TYPE
  when "all"
    Formula.all(eval_all: true)
  when "tap"
    Tap.fetch(COMMAND_ARG).formula_files.map(&Formulary.method(:factory))
  when "formula"
    [Formulary.factory(COMMAND_ARG)]
  end
  .select { |f| f.service? || f.plist }
  .freeze

FORMULA_FILES = FORMULAE.map(&:path).freeze

CORE_FORMULAE = FORMULAE.select do |formula|
  formula.tap.core_tap?
end.freeze

CORE_FORMULAE_NAMES = CORE_FORMULAE.map(&:name).freeze

# This needs to be generated before clearing the Formulary cache or it will error out.
CORE_FORMULAE_JSON = begin
  Formula.generating_hash!
  json = CORE_FORMULAE.to_h do |formula|
    json = JSON.generate(formula.to_hash_with_variations)
    hash = JSON.parse(json)
    [hash["name"], hash.except("name")]
  end.freeze
  Formula.generated_hash!
  json
end.freeze

odie "No formulae with service blocks to compare according to the given criteria!" if FORMULA_FILES.empty?

Formulary.clear_cache

MACOS_DIR = Pathname("macos").expand_path.freeze
MACOS_DIR.mkdir

Homebrew::SimulateSystem.with(os: :macos) do
  FORMULA_FILES.each do |formula_file|
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

Formulary.clear_cache

LINUX_DIR = Pathname("linux").expand_path.freeze
LINUX_DIR.mkdir

Homebrew::SimulateSystem.with(os: :linux) do
  FORMULA_FILES.each do |formula_file|
    formula = Formulary.factory(formula_file)

    next unless formula.service.command?

    outfile = LINUX_DIR/"#{formula.service_name}.service"
    File.write(outfile, formula.service.to_systemd_unit)

    if formula.service.timed?
      outfile = LINUX_DIR/"#{formula.service_name}.timer"
      File.write(outfile, formula.service.to_systemd_timer)
    end
  end
end

return if CORE_FORMULAE.empty?

# Monkey patch call to JSON API with generated JSON.
module Homebrew
  module API
    module Formula
      unless respond_to? :all_formulae
        abort "#{self}.all_formulae is no longer defined in Brew and cannot be monkey patched!"
      end

      def self.all_formulae
        CORE_FORMULAE_JSON
      end
    end
  end
end

Formulary.clear_cache

MACOS_API_DIR = Pathname("macos_api").expand_path.freeze
MACOS_API_DIR.mkdir

Homebrew::SimulateSystem.with(os: :macos) do
  CORE_FORMULAE_NAMES.each do |formula_name|
    formula = Formulary::FormulaAPILoader.new(formula_name).get_formula(:stable)

    service_content =
      if formula.service.command?
        formula.service.to_plist
      elsif formula.plist
        formula.plist
      end

    next if service_content.nil?

    outfile = MACOS_API_DIR/"#{formula.plist_name}.plist"
    File.write(outfile, service_content)
  end
end

Formulary.clear_cache

LINUX_API_DIR = Pathname("linux_api").expand_path.freeze
LINUX_API_DIR.mkdir

Homebrew::SimulateSystem.with(os: :linux) do
  CORE_FORMULAE_NAMES.each do |formula_name|
    formula = Formulary::FormulaAPILoader.new(formula_name).get_formula(:stable)

    next unless formula.service.command?

    outfile = LINUX_API_DIR/"#{formula.service_name}.service"
    File.write(outfile, formula.service.to_systemd_unit)

    if formula.service.timed?
      outfile = LINUX_API_DIR/"#{formula.service_name}.timer"
      File.write(outfile, formula.service.to_systemd_timer)
    end
  end
end
