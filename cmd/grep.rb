# frozen_string_literal: true

module Homebrew
  def self.grep_args
    Homebrew::CLI::Parser.new do
      usage_banner "`grep` <query>"
      description <<~EOS
        Search for matching name and description data in casks and formula
        using `git grep`. This only works for local taps and not with the
        core JSON APIs.

        This is mostly just a proof-of-concept alternative to `brew desc`
        which doesn't require
      EOS

      named_args number: 1
    end
  end

  # Ex. `homebrew/homebrew-cask/Casks/a/all-in-one-messenger.rb:  name "All-in-One Messenger"`
  NAME_OR_DESC_REGEX = %r{
    ^
    (?<user>[\w-]+)/            # homebrew/
    (:?homebrew-)?              # homebrew-
    (?<repo>[\w-]+)/            # cask-fonts/
    (?<cask>(:?Casks/)?)        # Casks/
    (:?[^/]+/)*                 # a/
    (?<package>\S+)\.rb         # all-in-one-messenger.rb
    :\s\s                       # `:  `
    (?<command>name|desc)       # name
    \s+                         # ` `
    "(?<string>(:?[^"]|\\")+)"  # "All-in-One Messenger"
    \s*
    $
  }x.freeze

  def self.query_to_regex(query)
    query.downcase
         .gsub(/[^a-z0-9]/, "")
         .chars
         .join("[^a-z0-9]*")
         .then { |query| /#{query}/i }
         .freeze
  end

  def self.grep
    args = grep_args.parse
    query = args.named.first
    query = query_to_regex(query)

    git_grep = [
      "git", "-C", (HOMEBREW_LIBRARY / "Taps").to_s,
      "grep", "--no-index",
      "-E", "^  (desc|name)[ ]+\"",
      "--", "*.rb"
    ].freeze

    cask_names = Hash.new { |hash, key| hash[key] = [] }
    cask_descriptions = {}
    formula_descriptions = {}

    Utils.safe_popen_read(*git_grep).lines.each do |line|
      match = line.match(NAME_OR_DESC_REGEX)
      next (puts line) if match.nil?

      case match[:command]
      when "desc"
        if match[:cask].empty?
          formula_descriptions[match[:package]] = match[:string]
        else
          cask_descriptions[match[:package]] = match[:string]
        end
      when "name"
        cask_names[match[:package]] << match[:string]
      end
    end

    cask_names.transform_values! { |names| names.join(", ") }

    formulae = formula_descriptions.select do |name, description|
      query.match?(name) || query.match?(description)
    end

    ohai "Formulae"
    formulae.sort_by(&:first).each do |name, desc|
      puts "#{Tty.bold}#{name}:#{Tty.reset} #{desc}"
    end
    puts

    casks = (cask_descriptions.keys | cask_names.keys).select do |name|
      query.match?(name) || cask_names[name]&.match?(query) || cask_descriptions[name]&.match?(query)
    end

    ohai "Casks"
    casks.each do |name|
      names = cask_names.fetch(name)
      desc = cask_descriptions.fetch(name, "[no description]")
      puts "#{Tty.bold}#{name}:#{Tty.reset} (#{names}) #{desc}"
    end

    Homebrew.failed = true if formulae.empty? && casks.empty?
  end
end
