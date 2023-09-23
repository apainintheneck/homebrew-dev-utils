# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/hd_utils"

module Homebrew
  def self.branch_compare_args
    Homebrew::CLI::Parser.new do
      usage_banner "`branch-compare` [<options>] -- command"
      description <<~EOS
        Runs a brew command on both the current branch and the main branch
        and then diffs the output of both commands. This helps with debugging
        and assurance testing when making changes to important commands.

        Example: `brew branch-compare --quiet -- deps --installed`

        #{HDUtils::BranchDiff::WARNING_MESSAGE}
      EOS

      switch "--ignore-errors", description: "Continue diff when a command returns a non-zero exit code."
      switch "--with-stderr", description: "Combine stdout and stderr in diff output."
      switch "--word-diff", description: "Show word diff instead of default line diff."

      named_args :command, min: 1
    end
  end

  def self.branch_compare
    args = branch_compare_args.parse
    command = args.named

    HDUtils::BranchDiff.diff_output(
      command,
      quiet:         args.quiet?,
      word_diff:     args.word_diff?,
      with_stderr:   args.with_stderr?,
      ignore_errors: args.ignore_errors?,
    )
  end
end
