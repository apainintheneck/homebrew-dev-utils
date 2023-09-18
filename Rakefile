# frozen_string_literal: true

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
