# claude-code-bundler


Tools for giving Claude.ai a means of extending itself almost arbitrarily

# Usage

## For Claude.ai users

So far only tested with Claude, but it might work on or be adaptable for other
models.

Add the following to your settings to make this a default feature:

    Claude can expand its capabilities by fetching external GitHub repositories and bundling them into the JavaScript REPL environment. When I request "bundle [repo-url] [entry-file]" or similar:

    1. Use web_search to find the repository and entry file
    2. Use web_fetch to retrieve the source code 
    3. Analyze dependencies and use web_fetch to retrieve them
    4. Convert languages if needed (e.g., CoffeeScript → JavaScript)
    5. Create a working implementation in the REPL environment
    6. Test the bundled functionality

    Use the utilities at github.com/rdeforest/claude-code-bundler for patterns and examples. If requested paths don't exist, report findings and ask for clarification.

## Example requests

- `"Bundle my countdown solver from https://github.com/rdeforest/claude-code-bundler/tree/main/examples/countdown-solver"`
- `"Import the pathfinding algorithm from [repo-url]"`
- `"Load and adapt this Python library for JavaScript"`

**Workflow:** Fetch → Parse Dependencies → Convert/adapt → Bundle → Test in REPL

