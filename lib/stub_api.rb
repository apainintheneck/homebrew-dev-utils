# frozen_string_literal: true

require "env_config"

module StubAPI
  class Error < StandardError; end
  class UndefinedError < Error; end

  module Formula
    [:name, :json, :load_from_api].each do |method_name|
      define_singleton_method(method_name) do
        raise UndefinedError, "Stub the formula API with `StubAPI.formula!` first!"
      end
    end
  end

  def self.formula!
    validate_not_using_api!
    validate_core_formula_tap!
    require_relative "stub-api/formula"
  end

  module Cask
    [:name, :json, :load_from_api].each do |method_name|
      define_singleton_method(method_name) do
        raise UndefinedError, "Stub the cask API with `StubAPI.cask!` first!"
      end
    end
  end

  def self.cask!
    validate_not_using_api!
    validate_core_cask_tap!
    require_relative "stub-api/cask"
  end

  private_class_method def self.validate_not_using_api!
    return if Homebrew::EnvConfig.no_install_from_api?

    raise Error, "`HOMEBREW_NO_INSTALL_FROM_API` must be set to mock the API!"
  end

  private_class_method def self.validate_core_formula_tap!
    return if CoreTap.instance.installed?

    raise Error, "The core formula tap needs to be installed to mock the API!"
  end

  private_class_method def self.validate_core_cask_tap!
    return if Tap.default_cask_tap.installed?

    raise Error, "The default cask tap needs to be installed to mock the API!"
  end
end
