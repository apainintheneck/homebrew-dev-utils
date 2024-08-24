# frozen_string_literal: true

require "English"
require "pathname"

ANSI_CODE_REGEX = /\e\[(\d+)m/

File.open("#{__dir__}/../README.md.new", "w") do |out_file|
  out_file.write <<~EOS
    # Brew Dev-utils

    A collection of commands and utilities that aim to make developer's lives a bit easier.

    ## How do I install these commands?

    Run `brew tap apainintheneck/dev-utils`.

    ## Documentation
  EOS

  Pathname("#{__dir__}/../cmd").children.sort.each do |command_file|
    next unless command_file.executable?
    next if command_file.extname != ".rb"

    command = command_file.basename(".rb").to_s
    help_page = `brew #{command} -h`.strip.gsub(ANSI_CODE_REGEX, "")

    abort "Invalid command: brew #{command} -h" unless $CHILD_STATUS.exitstatus.zero?

    out_file.write <<~EOS

      ### brew #{command}

      ```
      #{help_page}
      ```
    EOS
  end

  out_file.write <<~EOS

    ## Development

    Linting and readme checks along with integration tests are run on each pull request.
    All commands are run using the included Rakefile. Run `rake` to get the list of commands.
  EOS
end
