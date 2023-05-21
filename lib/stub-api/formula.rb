# frozen_string_literal: true

require "formula"

##################
# Mock Formula API
##################
# Generate the API JSON locally and mock the API loader to user that generated JSON.

# Add constant to module to avoid name conflicts.
module StubAPI
  module Formula
    NAMES = CoreTap
      .instance
      .formula_names
      .freeze
    
    print "Generating formulae API ..."
    
    # Generate json representation of all formulas.
    ::Formula.generating_hash!
    JSON = NAMES
      .to_h do |formula_name|
        formula = Formulary.factory(formula_name)
        json = JSON.generate(formula.to_hash_with_variations)
        hash = JSON.parse(json)
        [hash["name"], hash.except("name")]
      end
      .freeze
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

puts " and mocking formula API loader."

# Monkey patch call to JSON API with generated JSON.
module Homebrew
  module API
    module Formula
      def self.all_formulae
        StubAPI::Formula.json
      end
    end
  end
end
