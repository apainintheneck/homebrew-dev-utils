# frozen_string_literal: true

require "abstract_command"
require_relative "../lib/hd_utils"

module Homebrew
  module Cmd
    class BranchCompare < AbstractCommand
      cmd_args do
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
        switch "--time", description: "Benchmark the command on both branches."
        switch "--local", description: "Only load formula/cask from local taps not the API."

        named_args :command, min: 1
      end

      def run
        command = args.named

        ENV.delete("HOMEBREW_INTERNAL_JSON_V3")

        HDUtils::BranchDiff.diff_output(
          command,
          quiet:         args.quiet?,
          word_diff:     args.word_diff?,
          with_stderr:   args.with_stderr?,
          ignore_errors: args.ignore_errors?,
          no_api:        args.local?,
          benchmark:     args.time?,
        )
      end
    end
  end
end
