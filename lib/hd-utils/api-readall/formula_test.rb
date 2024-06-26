# frozen_string_literal: true

############################
# API Readall : Formula Test
############################
module HDUtils
  module APIReadall
    module FormulaTest
      def self.run(quiet:, verbose:, fail_fast:)
        error_count = 0
        error_lines = []
        StubAPI::Formula.names.each do |formula_name|
          StubAPI::Formula.load_from_api(formula_name).to_hash
        rescue => e
          raise if fail_fast

          error_count += 1
          error_lines << ">> #{formula_name} : #{e}"
          if verbose
            error_lines += e.backtrace
          else
            error_lines << e.backtrace.first
          end
          error_lines << ""
        end

        if error_count.zero?
          puts "Read core formulae and saw no failures!"
        else
          Homebrew.failed = true
          noun = (error_count == 1) ? "failure" : "failures"
          puts "Read core formulae and saw #{error_count} #{noun}!"

          unless quiet
            puts
            puts "Readall Failures: Formulae"
            puts "--------------------------"
            puts error_lines.join("\n")
          end
        end
      end
    end
  end
end
