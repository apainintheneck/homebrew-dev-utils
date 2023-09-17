# frozen_string_literal: true

require "tempfile"

module HDUtils
  module BranchDiff
    def self.run_command(command, quiet:, word_diff:, with_stderr: false, ignore_errors: false)
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
        
        output_files = [
          master_branch,
          current_branch,
        ].map do |branch|
          unless system("git checkout #{branch}", **quiet_options)
            odie "error checking out #{branch} branch"
          end
          
          outfile = Tempfile.new(branch)
          IO.popen(
            {"HOMEBREW_NO_AUTO_UPDATE" => "1"},
            [HOMEBREW_BREW_FILE, *command],
            **spawn_options
          ) do |pipe|
            outfile.write pipe.read
          end
          outfile.close
  
          if !ignore_errors && !$CHILD_STATUS.exitstatus.zero?
            odie "failure on #{branch} branch"
          end
  
          outfile
        end
  
        master_branch_outfile, current_branch_outfile = output_files.map(&:path)
  
        diff_command = %w[git diff --no-index]
        diff_command << "--word-diff" if word_diff
        diff_command << "--no-color" if ENV["HOMEBREW_NO_COLOR"]
        diff_command << master_branch_outfile
        diff_command << current_branch_outfile
  
        unless system(*diff_command)
          Homebrew.failed = true
        end
  
        output_files.each(&:unlink)
      ensure
        # Return user to the correct branch in the event of a failure
        system("git checkout #{current_branch}", out: File::NULL, err: File::NULL)
      end  
    end
  end
end
