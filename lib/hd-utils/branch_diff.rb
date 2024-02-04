# frozen_string_literal: true

require "benchmark"
require "shellwords"
require "tempfile"
require "tmpdir"

module HDUtils
  module BranchDiff
    WARNING_MESSAGE = <<~EOS.chomp.freeze
      Warning: This command runs git commands on the main brew repo.
      To be safe avoid running other brew commands simultaneously.
    EOS

    # Run a brew command on two branches and compare the output.
    def self.diff_output(command, quiet:, word_diff:, with_stderr:, ignore_errors:, no_api:, benchmark:)
      if command.first == "brew"
        odie "`brew` is not needed at the beginning of the subcommand"
      elsif !system("brew command #{command.first}", out: File::NULL, err: File::NULL)
        odie "Unknown command: `brew #{command.first}`"
      end

      quiet_options = quiet ? { out: File::NULL, err: File::NULL } : {}
      spawn_options = with_stderr ? { err: [:child, :out] } : {}
      benchmark_results = []
      env_variables = {}.tap do |hash|
        hash["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        hash["HOMEBREW_NO_INSTALL_FROM_API"] = "1" if no_api
      end

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
          odie "error checking out #{branch} branch" unless system("git switch #{branch}", **quiet_options)

          outfile = Tempfile.new(branch)
          time = Benchmark.measure do
            IO.popen(env_variables, [HOMEBREW_BREW_FILE, *command], **spawn_options) do |pipe|
              outfile.write pipe.read
            end
          end
          outfile.close

          benchmark_results << "#{branch} : #{time.real.round(2)} seconds"
          odie "failure on #{branch} branch" if !ignore_errors && !$CHILD_STATUS.exitstatus.zero?
          if Context.current.debug?
            puts
            puts "---Temp File Contents---"
            puts File.read(outfile.path)
            puts "------------------------"
            puts
          end

          outfile
        end

        diff_command = diff_command(*output_files.map(&:path), word_diff: word_diff)
        Homebrew.failed = true unless system(*diff_command)

        output_files.each(&:unlink)

        if benchmark
          puts
          puts "---Benchmark Results---"
          benchmark_results.each(&method(:puts))
        end
      ensure
        # Return user to the correct branch in the event of a failure
        system("git switch #{current_branch}", out: File::NULL, err: File::NULL)
      end
    end

    # Run a shell command on two brew branches (the current one and the master branch).
    #
    # 1. For each branch a command is run inside of a temporary directory.
    # 2. The command then writes files to the temporary directory.
    # 3. Afterwards the two temporary directories are diffed recursively.
    def self.diff_directories(command, quiet:, word_diff:, no_api:, stat:)
      command = Shellwords.join(command)
      quiet_options = quiet ? { out: File::NULL, err: File::NULL } : {}
      env_variables = {}.tap do |hash|
        hash["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        hash["HOMEBREW_NO_INSTALL_FROM_API"] = "1" if no_api
      end

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
          odie "error checking out #{branch} branch" unless system("git switch #{branch}", **quiet_options)

          tmp_dir = Dir.mktmpdir(branch)
          at_exit { FileUtils.remove_entry(tmp_dir) }

          Dir.chdir(tmp_dir) do
            odie "failure on #{branch} branch" unless system(env_variables, command)
            if Context.current.debug?
              puts
              puts "---Temp Directory Contents---"
              system("ls", "-l")
              puts "-----------------------------"
              puts
            end
          end

          tmp_dir
        end

        diff_command = diff_command(*output_directories, word_diff: word_diff, stat: stat)
        Homebrew.failed = true unless system(*diff_command)
      ensure
        # Return user to the correct branch in the event of a failure
        system("git switch #{current_branch}", out: File::NULL, err: File::NULL)
      end
    end

    # Check if the git repo in the current working directory has uncommitted
    # or untracked files in it and fails if it does.
    def self.dirty_git_repo_check!
      status = `git status --short`.strip
      return if status.empty?

      odie <<~ERROR
        The Brew repo has changes in progress according to `git status`.
        Stash or commit your work before running this command.

        -----
        $ git status --short
        #{status}
        -----
      ERROR
    end

    def self.diff_command(file_or_dir_1, file_or_dir_2, word_diff: false, stat: false)
      %w[git].tap do |args|
        args << "--no-pager" unless $stdout.tty?
        args << "diff" << "--no-index"
        args << "--word-diff" if word_diff
        args << "--stat" if stat
        args << "--no-color" if ENV["HOMEBREW_NO_COLOR"]
        args << file_or_dir_1
        args << file_or_dir_2
      end
    end

    private_class_method :dirty_git_repo_check!, :diff_command
  end
end
