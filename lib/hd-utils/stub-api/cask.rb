# frozen_string_literal: true

require "cask"

###############
# Mock Cask API
###############
# Generate the API JSON locally and mock the API loader to use that generated JSON.

# Add constants to module to avoid name conflicts.
module HDUtils
  module StubAPI
    module Cask
      abort "The core cask tap needs to be installed locally to mock the API!" unless CoreCaskTap.instance.installed?

      print "Generating cask API ..."

      # Generate json representation of all casks.
      ::Cask::Cask.generating_hash!
      JSON = CoreCaskTap.instance.cask_tokens.to_h do |cask_name|
        cask = ::Cask::CaskLoader.load(cask_name)
        json = JSON.generate(cask.to_hash_with_variations)
        hash = JSON.parse(json)
        [hash["token"], hash.except("token")]
      end.freeze
      ::Cask::Cask.generated_hash!

      NAMES = JSON.keys.freeze

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
end

puts " and mocking cask API loader."

require_relative "../extend/stub-api/cask"
