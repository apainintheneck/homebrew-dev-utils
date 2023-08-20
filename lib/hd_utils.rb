# frozen_string_literal: true

require "env_config"

# Needed to make autoload work (it was choking on relative paths before).
libdir = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

module HDUtils
  def self.validate_not_using_api!(reason:)
    return if Homebrew::EnvConfig.no_install_from_api?

    abort "`HOMEBREW_NO_INSTALL_FROM_API` must be set to #{reason}!"
  end

  autoload :APIReadall, "hd-utils/api_readall"
  autoload :StubAPI, "hd-utils/stub_api"
end
