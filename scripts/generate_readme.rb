# frozen_string_literal: true

require "english"
require "pathname"

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
    help_page = `brew #{command} -h`.strip

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

    - Linting
      - `rake lint:check`
      - `rake lint:fix`
    - Readme
      - `rake readme:outdated`
      - `rake readme:generate`
    - Integration Tests
      - `rake test:all`
        - Runs all of the following tests
      - `rake test:api-readall-test`
        - Very slow!
      - `rake test:branch-compare`
      - `rake test:service-diff`
  EOS
end
