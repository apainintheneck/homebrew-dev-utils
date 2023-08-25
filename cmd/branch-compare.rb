# frozen_string_literal: true

require "cli/parser"
require "tempfile"

module Homebrew
  def self.branch_compare_args
    Homebrew::CLI::Parser.new do
      usage_banner "`branch-compare` [<options>] -- command"
      description <<~EOS
        Runs a brew command on both the current branch and the main branch
        and then diffs the output of both commands. This helps with debugging
        and assurance testing when making changes to important commands.

        Example: `brew branch-compare -- deps --installed`
      EOS

      switch "--word-diff", description: "Show word diff instead of default line diff."

      named_args :command, min: 1
    end
  end

  def self.branch_compare
    args = branch_compare_args.parse
    command = args.named

    if command.first == "brew"
      odie "`brew` is not needed at the beginning of the subcommand"
    elsif !`brew commands --quiet`.lines(chomp: true).include?(command.first)
      odie "Unknown command: `brew #{command.first}`"
    end

    Dir.chdir(HOMEBREW_REPOSITORY) do
      master_branch = "master"
      current_branch = `git branch --show-current`.strip

      if master_branch == current_branch
        odie "Current branch is the master branch. Switch to a feature branch and try again."
      end
      
      output_files = [
        master_branch,
        current_branch,
      ].map do |branch|
        unless system("git checkout #{branch} #{"&>/dev/null" if args.quiet?}")
          odie "error checking out #{branch} branch"
        end
        
        outfile = Tempfile.new(branch)
        IO.popen({"HOMEBREW_NO_AUTO_UPDATE" => "1"}, [HOMEBREW_BREW_FILE, *command]) do |pipe|
          outfile.write pipe.read
        end
        outfile.close

        unless $CHILD_STATUS.exitstatus.zero?
          odie "failure on #{branch} branch"
        end

        outfile
      end

      master_branch_outfile, current_branch_outfile = output_files.map(&:path)

      diff_command = %w[git diff --no-index]
      diff_command << "--word-diff" if args.word_diff?
      diff_command << "--no-color" if ENV["HOMEBREW_NO_COLOR"]
      diff_command << master_branch_outfile
      diff_command << current_branch_outfile

      unless system(*diff_command)
        Homebrew.failed = true
      end

      output_files.each(&:unlink)
    ensure
      # Return user to the correct branch in the event of a failure
      system("git checkout #{current_branch} &> /dev/null")
    end
  end
end
