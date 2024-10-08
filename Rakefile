# frozen_string_literal: true

#
# Helpers
#

def log(text)
  $stderr.puts ">>> #{text}"
end

def cmd(*command)
  $stderr.print "$ "
  sh(*command)
end

def with_test_branch
  brew_directory = `brew --repo`.strip
  test_branch = "test-#{Time.now.to_i}"

  Dir.chdir(brew_directory) do
    current_branch = `git branch --show-current`.strip

    status = `git status --short`.strip
    unless status.empty?
      abort <<~ERROR
        The Brew repo has changes in progress according to `git status`.
        Stash or commit your work before running tests.

        -----
        $ git status --short
        #{status}
        -----
      ERROR
    end

    begin
      log "Setup"
      sh "git", "branch", test_branch, "master"
      sh "git", "switch", test_branch

      log "Test"
      yield
    ensure
      log "Cleanup"
      sh "git", "switch", current_branch
      sh "git", "branch", "-D", test_branch
    end
  end
end

#
# Tasks
#

task default: %w[tasks]

task :tasks do
  puts "Tasks"
  puts "-----"
  Rake.application.tasks.each do |task|
    puts "- #{task}"
  end
end

namespace "lint" do
  task :check do
    cmd "brew", "style", "apainintheneck/dev-utils"
  end

  task :fix do
    cmd "brew", "style", "apainintheneck/dev-utils", "--fix"
  end
end

namespace "readme" do
  task :outdated do
    ruby "scripts/generate_readme.rb"
    sh "diff", "README.md", "README.md.new"
  ensure
    rm_f "README.md.new"
  end

  task :generate do
    ruby "scripts/generate_readme.rb"
    mv "README.md.new", "README.md"
  ensure
    rm_f "README.md.new"
  end
end

namespace "test" do
  task :"api-readall-test" do
    cmd "brew", "api-readall-test", "--verbose"
  end

  task :"branch-compare" do
    with_test_branch do
      cmd "brew", "branch-compare", "--debug", "--", "help"
    end
  end

  task :"generate-api-diff" do
    with_test_branch do
      cmd "brew", "generate-api-diff", "--debug", "--cask"
      cmd "brew", "generate-api-diff", "--debug", "--formula"
    end
  end

  task :"service-diff" do
    with_test_branch do
      cmd "brew", "service-diff", "--debug"
    end
  end

  task :"startup-stats" do
    cmd "brew", "startup-stats", "--require", "tap"
  end

  task :all do
    %w[
      test:api-readall-test
      test:branch-compare
      test:generate-api-diff
      test:service-diff
      test:startup-stats
    ].each_with_index do |task, index|
      puts "--------------------" if index.positive?
      Rake::Task[task].invoke
    end
  end
end

INTEGRATION_TESTS_FILE = ".github/workflows/integration_tests.yml"
RAKE_TEST_REGEX = /^\s+- run:\s+rake\s+test:([a-zA-Z_-]+)\s*$/

task :"missing-tests" do
  abort "Missing integration test file: #{INTEGRATION_TESTS_FILE}" unless File.exist?(INTEGRATION_TESTS_FILE)

  integration_tests = File.foreach(INTEGRATION_TESTS_FILE).filter_map do |line|
    line[RAKE_TEST_REGEX, 1]
  end

  tap_commands = Dir.children("cmd").map do |file|
    file.chomp(".rb")
  end

  missing_tests = tap_commands - integration_tests

  unless missing_tests.empty?
    missing_test_list = missing_tests.map { |test| "- #{test}" }.join("\n")

    abort <<~EOS
      Missing integration tests for the following commands:
      #{missing_test_list}

      Add tests to the #{INTEGRATION_TESTS_FILE} file.
    EOS
  end
end
