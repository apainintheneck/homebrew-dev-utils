# frozen_string_literal: true

require "formula"

##################
# Mock Formula API
##################
# Generate the API JSON locally and mock the API loader to user that generated JSON.
CORE_FORMULA_NAMES = CoreTap
  .instance
  .formula_names
  .freeze

print "Generating formulae API ..."

# Generate json representation of all formulas.
Formula.generating_hash!
CORE_FORMULA_JSON = CORE_FORMULA_NAMES
  .to_h do |formula_name|
    formula = Formulary.factory(formula_name)
    json = JSON.generate(formula.to_hash_with_variations)
    hash = JSON.parse(json)
    [hash["name"], hash.except("name")]
  end
  .freeze
Formula.generated_hash!

# Monkey patch call to JSON API with generated JSON.
module Homebrew
  module API
    module Formula
      def self.all_formulae
        CORE_FORMULA_JSON
      end
    end
  end
end

puts " and mocking formulae API loader."

############################
# API Readall : Formula Test
############################
module APIReadall
  module FormulaTest
    def self.run(quiet:, verbose:, fail_fast:)
      unless CoreTap.instance.installed?
        raise "The core formula tap needs to be installed to run these tests!"
      end

      print "Reading core formulae ..."
  
      error_count = 0
      error_lines = []
      CORE_FORMULA_NAMES.each do |formula_name|
        load_test(formula_name)
      rescue => e
        raise if fail_fast

        error_count += 1
        error_lines << ">> #{formula_name} : #{e}"
        if verbose
          error_lines += e.backtrace
        else
          error_lines << e.backtrace.first
        end
        error_lines << ""
      end

      if error_count.zero?
        puts " and saw no failures!"
      else
        Homebrew.failed = true
        puts " and saw #{error_count} failures!"

        unless quiet
          puts
          puts "Readall Failures: Formulae"
          puts "--------------------------"
          puts error_lines.join("\n")
        end
      end
    end

    def self.load_test(formula_name)
      Formulary::FormulaAPILoader
        .new(formula_name)
        .get_formula(:stable)
        .to_hash
    end
  end
end
