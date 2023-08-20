# frozen_string_literal: true

# Monkey patch call to JSON API with generated JSON.
module Homebrew
  module API
    module Cask
      unless respond_to? :all_casks
        abort "#{self}.all_casks is no longer defined in Brew and cannot be monkey patched!"
      end

      def self.all_casks
        HDUtils::StubAPI::Cask.json
      end
    end
  end
end
