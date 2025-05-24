# claude-code-bundler


Tools for giving Claude.ai a means of extending itself almost arbitrarily

# Usage

## For Claude.ai users

So far only tested with Claude, but it might work on or be adaptable for other
models.

Add the following to your settings to make this a default feature:

    When I request "bundle [repo-url] [entry-file]" or similar, use the
    utilities at github.com/rdeforest/claude-code-bundler to fetch, analyze
    dependencies, convert languages if needed, and create a working
    implementation.

    If the requested path doesn't exist in the bundler repo, report your
    findings and ask the user for clarification.

## Example requests

- `"Bundle my countdown solver from https://github.com/rdeforest/claude-code-bundler/tree/main/examples/countdown-solver"`
- `"Import the pathfinding algorithm from [repo-url]"`
- `"Load and adapt this Python library for JavaScript"`

**Workflow:** Fetch → Parse Dependencies → Convert/adapt → Bundle → Test in REPL

