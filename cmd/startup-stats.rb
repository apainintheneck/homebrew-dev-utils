# frozen_string_literal: true

module Homebrew
  module Cmd
    class StartupStats < AbstractCommand
      cmd_args do
        usage_banner "`startup-stats` [<option>]"
        description <<~EOS
          Get information about the state of brew when a command
          is called. This includes loaded constants, requires
          and other such information.
        EOS

        switch "--requires", description: "List all requires made before this command was run."
        switch "--constants", description: "List all constants loaded before this command was run."

        conflicts "--requires", "--constants"
      end

      def run
        if args.requires?
          list_requires
        elsif args.constants?
          list_constants
        else
          odie "No options provided to the command!"
        end
      end

      def list_requires
        puts $LOADED_FEATURES.sort
      end

      def list_constants
        puts Object.constants.sort
      end
    end
  end
end