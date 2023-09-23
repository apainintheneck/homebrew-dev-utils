# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/hd_utils"

module Homebrew
  def self.generate_api_diff_args
    Homebrew::CLI::Parser.new do
      usage_banner "`generate-api-diff` [<options>]"
      description <<~EOS
        Compare the API generation before and and after changes
        to brew. This helps with debugging and assurance
        testing when making changes to the JSON API.

        Note: One of the `--cask` or `--formula` options is required.

        #{HDUtils::BranchDiff::WARNING_MESSAGE}
      EOS

      switch "--cask", description: "Run the diff on only core casks."
      switch "--formula", description: "Run the diff on only core formulae."
      switch "--word-diff", description: "Show word diff instead of default line diff."

      conflicts "--cask", "--formula"
    end
  end

  def self.generate_api_diff
    args = generate_api_diff_args.parse

    command =
      if args.formula?
        [HOMEBREW_BREW_FILE, "generate-formula-api"]
      elsif args.cask?
        [HOMEBREW_BREW_FILE, "generate-cask-api"]
      else
        require "help"
        Homebrew::Help.help "generate-api-diff"
      end

    HDUtils::BranchDiff.diff_directories(
      command,
      quiet:     args.quiet?,
      word_diff: args.word_diff?,
      no_api:    true,
    )
  end
end
