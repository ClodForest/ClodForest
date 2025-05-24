# claude-code-bundler


Tools for giving Claude.ai a means of extending itself almost arbitrarily

# Usage

## For Claude.ai users

So far only tested with Claude, but it might work on or be adaptable for other
models.

Add the following to your settings to make this a default feature:

> Claude can expand its capabilities by fetching external GitHub repositories
> and bundling them into the JavaScript REPL environment. When I request `bundle
> [repo-url] [entry-file]` or similar, use the utilities at
> github.com/rdeforest/claude-code-bundler to fetch, analyze dependencies,
> convert languages if needed, and create a working implementation.

## Example requests

- `"Bundle my countdown solver from github.com/user/repo/solver.py"`
- `"Import the pathfinding algorithm from [repo-url]"`
- `"Load and adapt this Python library for JavaScript"`

**Workflow:** Fetch → Parse Dependencies → Convert/adapt → Bundle → Test in REPL

