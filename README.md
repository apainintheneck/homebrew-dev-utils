# Brew Dev-utils

A collection of commands a utilities that aim to make developer's lives a bit easier.

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

Example: brew branch-compare -- deps --installed

      --word-diff                  Show word diff instead of default line diff.
  -d, --debug                      Display any debugging information.
  -q, --quiet                      Make some output more quiet.
  -v, --verbose                    Make some output more verbose.
  -h, --help                       Show this message.
```
