# frozen_string_literal: true

require "env_config"

# Needed to make autoload work (it was choking on relative paths before).
libdir = __dir__
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

module HDUtils
  autoload :APIReadall, "hd-utils/api_readall"
  autoload :BranchDiff, "hd-utils/branch_diff"
  autoload :StubAPI, "hd-utils/stub_api"
end
