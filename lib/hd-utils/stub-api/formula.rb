# frozen_string_literal: true

require "formula"

##################
# Mock Formula API
##################
# Generate the API JSON locally and mock the API loader to user that generated JSON.

# Add constant to module to avoid name conflicts.
module HDUtils
  module StubAPI
    module Formula
      abort "The core formula tap needs to be installed locally to mock the API!" unless CoreTap.instance.installed?

      NAMES = CoreTap.instance.formula_names.freeze

      print "Generating formulae API ..."

      # Generate json representation of all formulas.
      ::Formula.generating_hash!
      JSON = NAMES.to_h do |formula_name|
        formula = Formulary.factory(formula_name)
        json = JSON.generate(formula.to_api_hash)
        hash = JSON.parse(json)
        [hash["name"], hash.except("name")]
      end.freeze
      ::Formula.generated_hash!

      private_constant :NAMES, :JSON

      def self.names
        NAMES
      end

      def self.json
        JSON
      end

      def self.load_from_api(name)
        Formulary::FormulaAPILoader
          .new(name)
          .get_formula(:stable)
      end
    end
  end
end

warn " and mocking formula API loader."

require_relative "../extend/stub-api/formula"
