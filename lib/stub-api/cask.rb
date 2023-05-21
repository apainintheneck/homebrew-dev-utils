# frozen_string_literal: true

require "cask"

###############
# Mock Cask API
###############
# Generate the API JSON locally and mock the API loader to use that generated JSON.

# Add constants to module to avoid name conflicts.
module StubAPI
  module Cask
    NAMES = Tap
      .default_cask_tap
      .cask_tokens
      .freeze

    print "Generating cask API ..."

    # Generate json representation of all casks.
    ::Cask::Cask.generating_hash!
    JSON = NAMES
      .to_h do |cask_name|
        cask = ::Cask::CaskLoader.load(cask_name)
        json = JSON.generate(cask.to_hash_with_variations)
        hash = JSON.parse(json)
        [hash["token"], hash.except("token")]
      end
      .freeze
    ::Cask::Cask.generated_hash!

    private_constant :NAMES, :JSON

    def self.names
      NAMES
    end

    def self.json
      JSON
    end

    def self.load_from_api(token)
      ::Cask::CaskLoader::FromAPILoader
        .new(token)
        .load(config: nil)
    end
  end
end

puts " and mocking cask API loader."

# Monkey patch call to JSON API with generated JSON.
module Homebrew
  module API
    module Cask
      def self.all_casks
        StubAPI::Cask.json
      end
    end
  end
end
