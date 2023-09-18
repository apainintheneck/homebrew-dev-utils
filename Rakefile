# frozen_string_literal: true

#
# Helpers
#

def log(text)
  STDERR.puts ">>> #{text}"
end

def cmd(*command)
  print "$ "
  sh *command
end

def with_test_branch
  current_directory = Dir.pwd
  brew_directory = `brew --repo`.strip
  test_branch = "test-#{Time.now.to_i}"

  log "Setup"
  Dir.chdir(brew_directory)
  sh "git", "checkout", "-b", test_branch

  log "Test"
  yield
ensure
  log "Cleanup"
  sh "git", "checkout", "master"
  sh "git", "branch", "-d", test_branch
  Dir.chdir(current_directory)
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
    sh "brew", "style", __dir__
  end

  task :fix do
    sh "brew", "style", __dir__, "--fix"
  end
end

namespace "readme" do
  task :outdated do
    ruby "scripts/generate_readme.rb"
    sh "git", "diff", "--no-index", "README.md", "README.md.new"
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

  task :"service-diff" do
    with_test_branch do
      cmd "brew", "service-diff", "--formula=redis"
    end
  end

  task :all do
    %w[
      test:api-readall-test
      test:branch-compare
      test:service-diff
    ].each_with_index do |task, index|
      puts "--------------------" if index.positive?
      Rake::Task[task].invoke
    end
  end
end
