# Brew Dev-utils

A collection of commands and utilities that aim to make developer's lives a bit easier.

## How do I install these commands?

Run `brew tap apainintheneck/dev-utils`.

## Documentation

### brew api-readall-test

```
Usage: brew api-readall-test [options]

Test API generation and loading of core formulae and casks.

Note: This requires the core tap(s) to be installed locally,
HOMEBREW_NO_INSTALL_FROM_API gets set automatically before running and this
command is slow because it generates and then loads everything.

      --fail-fast                  Exit after the first failure.
      --formula, --formulae        Only test core formulae.
      --cask, --casks              Only test core casks.
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

### brew branch-compare

```
Usage: brew branch-compare [options] -- command

Runs a brew command on both the current branch and the main branch and then
diffs the output of both commands. This helps with debugging and assurance
testing when making changes to important commands.

Example: brew branch-compare --quiet -- deps --installed

Warning: This command runs git commands on the main brew repo. To be safe avoid
running other brew commands simultaneously.

      --ignore-errors              Continue diff when a command returns a
                                   non-zero exit code.
      --with-stderr                Combine stdout and stderr in diff output.
      --word-diff                  Show word diff instead of default line diff.
      --time                       Benchmark the command on both branches.
      --local                      Only load formula/cask from local taps not
                                   the API.
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

### brew generate-api-diff

```
Usage: brew generate-api-diff [options]

Compare the API generation before and and after changes to brew. This helps with
debugging and assurance testing when making changes to the JSON API.

Note: One of the --cask or --formula options is required.

Warning: This command runs git commands on the main brew repo. To be safe avoid
running other brew commands simultaneously.

      --cask                       Run the diff on only core casks.
      --formula                    Run the diff on only core formulae.
      --word-diff                  Show word diff instead of default line diff.
      --stat                       Shows condensed output based on git
                                   diff --stat
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

### brew service-diff

```
Usage: brew service-diff [options]

Compare the service file generation on macOS and Linux before and after changes
to brew. This helps with debugging and assurance testing when making changes to
the brew services DSL.

Warning: This command runs git commands on the main brew repo. To be safe avoid
running other brew commands simultaneously.

      --formula                    Run the diff on only one formula.
      --tap                        Run the diff on only one tap.
      --word-diff                  Show word diff instead of default line diff.
      --stat                       Shows condensed output based on git
                                   diff --stat
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

### brew startup-stats

```
Usage: brew startup-stats [option]

Get information about the state of brew at the time a command is called. This
includes loaded constants, requires and other such information.

      --defined                    Check if a constant is defined.
      --require                    Diagnostics about a single require statement.
      --list-requires              List all requires made before this command
                                   was run.
      --list-constants             List all constants loaded before this command
                                   was run.
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

## Development

Linting and readme checks along with integration tests are run on each pull request.
All commands are run using the included Rakefile. Run `rake` to get the list of commands.
