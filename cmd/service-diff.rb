# frozen_string_literal: true

require "cli/parser"
require_relative "../lib/hd_utils"

module Homebrew
  module Cmd
    class ServiceDiff < AbstractCommand
      cmd_args do
        usage_banner "`service-diff` [<options>]"
        description <<~EOS
          Compare the service file generation on macOS and Linux before
          and after changes to brew. This helps with debugging and assurance
          testing when making changes to the `brew services` DSL.

          #{HDUtils::BranchDiff::WARNING_MESSAGE}
        EOS

        flag "--formula=", description: "Run the diff on only one formula."
        flag "--tap=", description: "Run the diff on only one tap."
        switch "--word-diff", description: "Show word diff instead of default line diff."
        switch "--stat", description: "Shows condensed output based on `git diff --stat`"

        conflicts "--tap=", "--formula="
        conflicts "--word-diff", "--stat"
      end

      def run
        ENV.delete("HOMEBREW_INTERNAL_JSON_V3")

        script_path = File.expand_path("../lib/diff-scripts/service_diff.rb", __dir__)
        odie "Script #{script_path} doesn't exist!" unless File.exist?(script_path)

        script_args =
          if args.tap
            ["tap", args.tap]
          elsif args.formula
            ["formula", args.formula]
          else
            ["all"]
          end

        command = [HOMEBREW_BREW_FILE, "ruby", "--", script_path, *script_args]

        HDUtils::BranchDiff.diff_directories(
          command,
          quiet:     args.quiet?,
          word_diff: args.word_diff?,
          stat:      args.stat?,
          no_api:    true,
        )
      end
    end
  end
end
