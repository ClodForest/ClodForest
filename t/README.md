# ClodForest Coordinator Test Suite

This directory contains the test suite for the ClodForest Coordinator service, built using the [bevry/kava](https://github.com/bevry/kava) testing framework.

## Test Structure

- `index.coffee` - Main test runner and basic application tests
- `config.test.coffee` - Configuration module tests
- `apis.test.coffee` - API business logic tests
- `routing.test.coffee` - HTTP routing and endpoint tests
- `integration.test.coffee` - Full application integration tests

## Running Tests

### Basic Test Run
```bash
npm test
```

### Verbose Output
```bash
npm run test:verbose
```

### Watch Mode (runs tests when files change)
```bash
npm run test:watch
```

### Direct Kava Usage
```bash
# Run all tests
coffee t/

# Run specific test file
coffee t/config.test.coffee

# Run with verbose output
coffee t/ --verbose
```

## Test Categories

### Configuration Tests (`config.test.coffee`)
- Validates all required configuration keys are present
- Tests PORT validation
- Verifies API paths configuration
- Checks CORS origins setup
- Validates feature flags
- Tests environment detection logic

### API Tests (`apis.test.coffee`)
- Tests all API function exports
- Validates welcome data structure
- Tests health check responses
- Verifies time service functionality
- Tests repository operations
- Validates instance tracking
- Tests admin HTML generation
- Verifies git command security

### Routing Tests (`routing.test.coffee`)
- Tests HTTP endpoint responses
- Validates content type handling (JSON/YAML/HTML)
- Tests error handling (404, 500)
- Verifies POST endpoint functionality
- Tests Accept header handling
- Validates instance registration

### Integration Tests (`integration.test.coffee`)
- Tests full application startup
- Validates graceful shutdown handling
- Tests cross-module consistency
- Verifies security configurations
- Tests file operation safety
- Validates git command security
- Tests instance tracking consistency

## Test Framework Features

The bevry/kava framework provides:

- **Asynchronous Testing**: All tests use callback-based async patterns
- **Suite Organization**: Tests are organized into logical suites
- **Error Handling**: Comprehensive error reporting
- **CoffeeScript Native**: Written in CoffeeScript for consistency
- **Minimal Dependencies**: Lightweight testing framework

## Writing New Tests

### Basic Test Structure
```coffeescript
kava = require 'kava'

kava.suite 'My Test Suite', (suite, test) ->
  
  test 'should do something', (done) ->
    # Test logic here
    if condition
      done() # Success
    else
      done(new Error('Test failed')) # Failure
```

### Async Testing Pattern
```coffeescript
test 'should handle async operations', (done) ->
  someAsyncFunction (err, result) ->
    if err
      return done(err)
    
    if result isnt expectedValue
      return done(new Error('Unexpected result'))
    
    done()
```

### HTTP Testing Pattern
```coffeescript
test 'should test HTTP endpoint', (done) ->
  createTestServer (server, port) ->
    makeRequest port, {path: '/api/test'}, (err, res, body) ->
      server.close()
      if err
        return done(err)
      
      if res.statusCode isnt 200
        return done(new Error("Expected 200, got #{res.statusCode}"))
      
      done()
```

## Test Coverage

The test suite covers:

- ✅ Configuration validation
- ✅ API business logic
- ✅ HTTP routing and responses
- ✅ Error handling
- ✅ Security validations
- ✅ Integration scenarios
- ✅ Instance tracking
- ✅ File operations
- ✅ Git command security

## Continuous Integration

Tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Tests
  run: npm test
```

## Debugging Tests

For debugging failed tests:

1. Use verbose mode: `npm run test:verbose`
2. Run individual test files: `kava t/specific.test.coffee`
3. Add console.log statements in test code
4. Check server logs if testing HTTP endpoints

## Dependencies

The test suite uses minimal dependencies:
- `kava` - Testing framework
- Built-in Node.js modules (`http`, `fs`, `path`)
- Application modules under test

No external HTTP testing libraries (like supertest) are used to keep dependencies minimal.
