# frozen_string_literal: true

module HDUtils
  module StubAPI
    autoload :Formula, "hd-utils/stub-api/formula"
    autoload :Cask, "hd-utils/stub-api/cask"

    def self.formula!
      StubAPI::Formula
    end

    def self.cask!
      StubAPI::Cask
    end
  end
end
