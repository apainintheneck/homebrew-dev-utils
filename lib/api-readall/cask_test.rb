# frozen_string_literal: true

require "cask"

###############
# Mock Cask API
###############
# Generate the API JSON locally and mock the API loader to user that generated JSON.
CORE_CASK_NAMES = Tap
  .default_cask_tap
  .cask_tokens
  .freeze

print "Generating cask API ..."

# Generate json representation of all casks.
Cask::Cask.generating_hash!
CORE_CASK_JSON = CORE_CASK_NAMES
  .to_h do |cask_name|
    cask = Cask::CaskLoader.load(cask_name)
    json = JSON.generate(cask.to_hash_with_variations)
    hash = JSON.parse(json)
    [hash["token"], hash.except("token")]
  end
  .freeze
Cask::Cask.generated_hash!

# Monkey patch call to JSON API with generated JSON.
module Homebrew
  module API
    module Cask
      def self.all_casks
        CORE_CASK_JSON
      end
    end
  end
end

puts " and mocking cask API loader."

#########################
# API Readall : Cask Test
#########################
module APIReadall
  module CaskTest
    def self.run(quiet:, verbose:, fail_fast:)
      unless Tap.default_cask_tap.installed?
        raise "The default cask tap needs to be installed to run these tests!"
      end
  
      print "Reading core casks ..."

      error_count = 0
      error_lines = []
      CORE_CASK_NAMES.each do |cask_name|
        load_test(cask_name)
      rescue => e
        raise if fail_fast

        error_count += 1
        error_lines << ">> #{cask_name} : #{e}"
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
          puts "Readall Failures: Casks"
          puts "-----------------------"
          puts error_lines.join("\n")
        end
      end
    end

    def self.load_test(cask_token)
      Cask::CaskLoader::FromAPILoader
        .new(cask_token)
        .load(config: nil)
        .to_h
    end
  end
end
