# frozen_string_literal: true

#########################
# API Readall : Cask Test
#########################
module HDUtils
  module APIReadall
    module CaskTest
      def self.run(quiet:, verbose:, fail_fast:)
        error_count = 0
        error_lines = []
        StubAPI::Cask.names.each do |cask_name|
          StubAPI::Cask.load_from_api(cask_name).to_h
        rescue => e
          raise if fail_fast

          error_count += 1
          error_lines << ">> #{cask_name} : #{e}"
          if verbose
            error_lines += e.backtrace
          else
            error_lines << e.backtrace.first
          end
          error_lines << ""
        end

        if error_count.zero?
          puts "Read core casks and saw no failures!"
        else
          Homebrew.failed = true
          noun = error_count == 1 ? "failure" : "failures"
          puts "Read core casks and saw #{error_count} #{noun}!"

          unless quiet
            puts
            puts "Readall Failures: Casks"
            puts "-----------------------"
            puts error_lines.join("\n")
          end
        end
      end
    end
  end
end
