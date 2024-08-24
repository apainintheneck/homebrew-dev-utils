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

        flag "--defined=", description: "Check if a constant is defined."
        flag "--require=", description: "Benchmark a single require statement."
        switch "--list-requires", description: "List all requires made before this command was run."
        switch "--list-constants", description: "List all constants loaded before this command was run."

        %w[
          --defined
          --require
          --list-requires
          --list-constants
        ].combination(2) do |combo|
          conflicts *combo
        end
      end

      def run
        if args.defined
          puts Object.const_defined?(args.defined)
        elsif args.require
          require_diagnostics
        elsif args.list_requires?
          puts require_list
        elsif args.list_constants?
          puts constant_list
        else
          odie "No options provided to the command!"
        end
      end

      def require_list
        $LOADED_FEATURES.sort
      end

      def constant_list
        Object.constants.sort
      end

      def require_diagnostics
        odie "'brew' cannot be required directly." if args.require == "brew"

        begin
          before_require_list = require_list
          before_constant_list = constant_list

          hash = benchmark { require args.require }
          hash => { result:, elapsed_seconds: }

          new_require_list = require_list - before_require_list
          new_constant_list = constant_list - before_constant_list

          if result
            oh1 "require '#{args.require}'"
            ohai "elapsed seconds"
            puts "- #{elapsed_seconds}"
            if new_require_list.any?
              puts
              ohai "new requires"
              new_require_list.each { puts "- #{_1}" }
            end
            if new_constant_list.any?
              puts
              ohai "new constants"
              new_constant_list.each { puts "- #{_1}" }
            end
          else
            odie "'#{args.require}' has already been required."
          end
        rescue LoadError => e
          odie e.to_s
        end
      end

      def benchmark
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = yield
        end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        elapsed_seconds = end_time - start_time
        { result:, elapsed_seconds: }
      end
    end
  end
end