# frozen_string_literal: true

#
# Helpers
#

def log(text)
  $stderr.puts ">>> #{text}"
end

def cmd(*command)
  print "$ "
  sh(*command)
end

def with_test_branch
  brew_directory = `brew --repo`.strip
  test_branch = "test-#{Time.now.to_i}"

  Dir.chdir(brew_directory) do
    current_branch = `git branch --show-current`.strip

    unless `git status --short`.strip.empty?
      abort <<~ERROR
        The Brew repo has changes in progress according to `git status`.
        Stash or commit your work before running tests.
      ERROR
    end

    begin
      log "Setup"
      sh "git", "branch", test_branch, "master"
      sh "git", "checkout", test_branch

      log "Test"
      yield
    ensure
      log "Cleanup"
      sh "git", "checkout", current_branch
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
    cmd "brew", "api-readall-test"
  end

  task :"branch-compare" do
    with_test_branch do
      cmd "brew", "branch-compare", "--", "help"
    end
  end

  task :"generate-api-diff" do
    with_test_branch do
      cmd "brew", "generate-api-diff", "--cask"
      cmd "brew", "generate-api-diff", "--formula"
    end
  end

  task :"service-diff" do
    with_test_branch do
      cmd "brew", "service-diff", "--formula=redis"
    end
  end

  task :all do
    %w[
      test:api-readall-test
      test:branch-compare
      test:generate-api-diff
      test:service-diff
    ].each_with_index do |task, index|
      puts "--------------------" if index.positive?
      Rake::Task[task].invoke
    end
  end
end
