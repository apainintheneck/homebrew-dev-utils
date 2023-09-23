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

Warning: This command uses git functions on the main brew repo. To be safe avoid
running other brew commands simultaneously.

      --ignore-errors              Continue diff when a command returns a
                                   non-zero exit code.
      --with-stderr                Combine stdout and stderr in diff output.
      --word-diff                  Show word diff instead of default line diff.
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

Warning: This command uses git functions on the main brew repo. To be safe avoid
running other brew commands simultaneously.

      --formula                    Run the diff on only one formula.
      --tap                        Run the diff on only one tap.
      --word-diff                  Show word diff instead of default line diff.
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```

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
