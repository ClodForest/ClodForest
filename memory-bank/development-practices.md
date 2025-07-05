# Development Practices for ClodForest

## Server Management
- ✅ Use `npm run kill` followed by `npm run start` for clean server restarts
- ✅ Use `npm run logs` to check server output instead of `tail -f`
- ✅ Check logs/ directory files directly instead of using tail commands
- ❌ Don't use `coffee src/app.coffee` directly for testing
- ❌ Don't use `tail -f` (it gets stuck)
- ❌ Don't repeatedly stop/start server during development

## Development Workflow
- ✅ Use `coffee -c filename.coffee` to validate syntax before testing
- ✅ Make one change at a time and test each change rigorously
- ✅ Use standard npm commands for all operations
- ✅ Look up documentation instead of guessing at configurations
- ✅ Validate assumptions before proceeding
- ✅ Ask questions when uncertain rather than iterating blindly

## Quality Standards
- ✅ Be skeptical of my own assumptions
- ✅ Research proper configuration patterns for libraries
- ✅ Test incrementally but efficiently
- ✅ Stay rigorous in operations

## Current Task Context
- Working on replacing oauth2-server with oidc-provider
- Need to research proper oidc-provider configuration for registration
- Error: "registration policies are only available in conjunction with adapter-backed initial access tokens"
- Must find documentation to solve configuration issues properly
