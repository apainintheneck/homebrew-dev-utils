# frozen_string_literal: true

require "shellwords"
require "tempfile"
require "tmpdir"

module HDUtils
  module BranchDiff
    WARNING_MESSAGE = <<~EOS.chomp.freeze
      Warning: This command uses git functions on the main brew repo.
      To be safe avoid running other brew commands simultaneously.
    EOS

    # Run a brew command on two branches and compare the output.
    def self.diff_output(command, quiet:, word_diff:, with_stderr:, ignore_errors:)
      if command.first == "brew"
        odie "`brew` is not needed at the beginning of the subcommand"
      elsif !system("brew command #{command.first}", out: File::NULL, err: File::NULL)
        odie "Unknown command: `brew #{command.first}`"
      end

      quiet_options = quiet ? { out: File::NULL, err: File::NULL } : {}
      spawn_options = with_stderr ? { err: [:child, :out] } : {}

      Dir.chdir(HOMEBREW_REPOSITORY) do
        master_branch = "master"
        current_branch = `git branch --show-current`.strip

        if master_branch == current_branch
          odie "Current branch is the master branch. Switch to a feature branch and try again."
        end

        dirty_git_repo_check!

        output_files = [
          master_branch,
          current_branch,
        ].map do |branch|
          odie "error checking out #{branch} branch" unless system("git checkout #{branch}", **quiet_options)

          outfile = Tempfile.new(branch)
          IO.popen(
            { "HOMEBREW_NO_AUTO_UPDATE" => "1" },
            [HOMEBREW_BREW_FILE, *command],
            **spawn_options,
          ) do |pipe|
            outfile.write pipe.read
          end
          outfile.close

          odie "failure on #{branch} branch" if !ignore_errors && !$CHILD_STATUS.exitstatus.zero?

          outfile
        end

        master_branch_outfile, current_branch_outfile = output_files.map(&:path)

        diff_command = %w[git diff --no-index]
        diff_command << "--word-diff" if word_diff
        diff_command << "--no-color" if ENV["HOMEBREW_NO_COLOR"]
        diff_command << master_branch_outfile
        diff_command << current_branch_outfile

        Homebrew.failed = true unless system(*diff_command)

        output_files.each(&:unlink)
      ensure
        # Return user to the correct branch in the event of a failure
        system("git checkout #{current_branch}", out: File::NULL, err: File::NULL)
      end
    end

    # Run a shell command on two brew branches (the current one and the master branch).
    #
    # 1. For each branch a command is run inside of a temporary directory.
    # 2. The command then writes files to the temporary directory.
    # 3. Afterwards the two temporary directories are diffed recursively.
    def self.diff_directories(command, quiet:, word_diff:)
      command = Shellwords.join(command)
      quiet_options = quiet ? { out: File::NULL, err: File::NULL } : {}

      Dir.chdir(HOMEBREW_REPOSITORY) do
        master_branch = "master"
        current_branch = `git branch --show-current`.strip

        if master_branch == current_branch
          odie "Current branch is the master branch. Switch to a feature branch and try again."
        end

        dirty_git_repo_check!

        output_directories = [
          master_branch,
          current_branch,
        ].map do |branch|
          odie "error checking out #{branch} branch" unless system("git checkout #{branch}", **quiet_options)

          tmp_dir = Dir.mktmpdir(branch)
          at_exit { FileUtils.remove_entry(tmp_dir) }

          Dir.chdir(tmp_dir) do
            odie "failure on #{branch} branch" unless system({ "HOMEBREW_NO_AUTO_UPDATE" => "1" }, command)
          end

          tmp_dir
        end

        master_branch_out_dir, current_branch_out_dir = output_directories

        diff_command = %w[git diff --no-index]
        diff_command << "--word-diff" if word_diff
        diff_command << "--no-color" if ENV["HOMEBREW_NO_COLOR"]
        diff_command << master_branch_out_dir
        diff_command << current_branch_out_dir

        Homebrew.failed = true unless system(*diff_command)
      ensure
        # Return user to the correct branch in the event of a failure
        system("git checkout #{current_branch}", out: File::NULL, err: File::NULL)
      end
    end

    # Check if the git repo in the current working directory has uncommitted
    # or untracked files in it and fails if it does.
    def self.dirty_git_repo_check!
      return if `git status --short`.strip.empty?

      odie <<~ERROR
        The Brew repo has changes in progress according to `git status`.
        Stash or commit your work before running tests.
      ERROR
    end
  end
end
