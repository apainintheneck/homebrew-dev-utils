# frozen_string_literal: true

# Monkey patch call to JSON API with generated JSON.
module Homebrew
  module API
    module Formula
      unless respond_to? :all_formulae
        abort "#{self}.all_formulae is no longer defined in Brew and cannot be monkey patched!"
      end

      def self.all_formulae
        HDUtils::StubAPI::Formula.json
      end
    end
  end
end
