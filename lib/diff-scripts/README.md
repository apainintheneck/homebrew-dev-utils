## Diff Scripts

These are Ruby scripts run internally by the `BranchDiff.diff_directory` method to compare results between branches. An example of this is the `brew service-diff` command.

The script is expected to write output files to the current directory (it is called from inside a temporary directory) and then the directories are diffed recursively.

The command that gets run by the `BranchDiff.diff_directory` method should be something like the following.

```rb
# Note: In this example, we are expanding the path from the `cmd/` directory.
script_path = File.expand_path("../lib/diff-scripts/<script>.rb", __dir__)
command = [HOMEBREW_BREW_FILE, "ruby", "--", script_path, *script_args]
```
