# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/hd_utils"

module Homebrew
  def self.api_readall_test_args
    Homebrew::CLI::Parser.new do
      usage_banner "`api-readall-test` [<options>]"
      description <<~EOS
        Test API generation and loading of core formulae and casks.

        Note: This requires the core tap(s) to be installed locally,
        `HOMEBREW_NO_INSTALL_FROM_API` gets set automatically before running and
        this command is slow because it generates and then loads everything.
      EOS

      switch "--fail-fast", description: "Exit after the first failure."
      switch "--formula", "--formulae", description: "Only test core formulae."
      switch "--cask", "--casks", description: "Only test core casks."

      conflicts "--formula", "--cask"
    end
  end

  def self.api_readall_test
    args = api_readall_test_args.parse

    ENV.delete("HOMEBREW_INTERNAL_JSON_V3")

    Homebrew.with_no_api_env do
      unless args.cask?
        HDUtils::APIReadall::FormulaTest.run(
          quiet:     args.quiet?,
          verbose:   args.verbose?,
          fail_fast: args.fail_fast?,
        )
      end

      puts if !args.formula? && !args.cask?

      unless args.formula?
        HDUtils::APIReadall::CaskTest.run(
          quiet:     args.quiet?,
          verbose:   args.verbose?,
          fail_fast: args.fail_fast?,
        )
      end
    end
  end
end
