# JSON-RPC Echo Server

A lightweight, zero-dependency JSON-RPC 2.0 echo server built with pure Node.js and CoffeeScript.

## Features

- **Zero Dependencies**: Uses only Node.js built-in modules (except CoffeeScript)
- **JSON-RPC 2.0 Compliant**: Full protocol implementation with error handling
- **Multiple Echo Methods**: Simple, enhanced, delayed, and error testing methods
- **CORS Support**: Ready for browser-based clients
- **Batch Requests**: Support for JSON-RPC batch operations
- **Health Monitoring**: Built-in health check endpoint
- **Web Interface**: HTML welcome page with documentation

## Quick Start

```bash
# Start the server
coffee src/echo/index.coffee

# Test the server
coffee src/echo/test.coffee

# Or test manually with curl
curl -X POST http://localhost:8081/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"echo.simple","params":{"message":"Hello!"},"id":1}'
```

## API Endpoints

- `POST /rpc` - JSON-RPC endpoint
- `GET /health` - Health check
- `GET /` - Welcome page with documentation

## Available Methods

### `echo.simple`
Returns exactly what was sent in the params.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "echo.simple",
  "params": {"message": "Hello, World!"},
  "id": 1
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {"message": "Hello, World!"},
  "id": 1
}
```

### `echo.enhanced`
Returns params plus server metadata.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "echo.enhanced",
  "params": {"test": "data"},
  "id": 2
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "result": {
    "echo": {"test": "data"},
    "metadata": {
      "timestamp": "2025-06-28T17:05:00.000Z",
      "server": "JSON-RPC Echo Server",
      "version": "1.0.0",
      "method": "echo.enhanced"
    }
  },
  "id": 2
}
```

### `echo.delay`
Echoes after a specified delay (useful for testing async behavior).

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "echo.delay",
  "params": {"message": "Delayed!", "delay_ms": 1000},
  "id": 3
}
```

**Response:** (after 1 second)
```json
{
  "jsonrpc": "2.0",
  "result": {
    "echo": {"message": "Delayed!", "delay_ms": 1000},
    "delayed": 1000,
    "executed": "2025-06-28T17:05:01.000Z"
  },
  "id": 3
}
```

### `echo.error`
Intentionally returns errors for testing error handling.

**Request:**
```json
{
  "jsonrpc": "2.0",
  "method": "echo.error",
  "params": {"error_type": "generic"},
  "id": 4
}
```

**Response:**
```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32603,
    "message": "Intentional test error"
  },
  "id": 4
}
```

## Configuration

Environment variables:

- `ECHO_PORT` or `PORT` - Server port (default: 8081)
- `NODE_ENV` - Environment (development/production)

## Architecture

```
src/echo/
├── index.coffee          # Main server entry point
├── lib/
│   ├── config.coffee     # Configuration management
│   ├── utils.coffee      # HTTP utilities and CORS
│   ├── jsonrpc.coffee    # JSON-RPC 2.0 protocol handler
│   └── router.coffee     # Simple URL routing
├── methods/
│   └── echo.coffee       # Echo method implementations
├── test.coffee           # Test script
└── README.md            # This file
```

## JSON-RPC 2.0 Compliance

- ✅ Request/Response format validation
- ✅ Error code standardization (-32700 to -32603)
- ✅ Batch request support
- ✅ Notification handling (no response)
- ✅ Parameter validation
- ✅ Method not found handling

## Error Codes

- `-32700` Parse error (invalid JSON)
- `-32600` Invalid Request (malformed JSON-RPC)
- `-32601` Method not found
- `-32602` Invalid params
- `-32603` Internal error

## Testing

The included test script validates:
- All echo methods
- Error handling
- JSON-RPC protocol compliance
- Server health

```bash
coffee src/echo/test.coffee
```

## Use Cases

- **JSON-RPC Client Testing**: Test your JSON-RPC clients against a known-good server
- **Protocol Validation**: Verify JSON-RPC 2.0 compliance
- **Network Testing**: Test connectivity, latency, and error handling
- **Development Reference**: Example of zero-dependency Node.js HTTP server

## Design Philosophy

Following ClodForest coding standards:
- **Minimalism**: Zero external dependencies
- **Unix Philosophy**: Do one thing well
- **Self-Documenting**: Clear code structure
- **Vertical Alignment**: Readable configuration
- **Honesty**: No mock data, real behavior testing

## Performance

Lightweight and fast:
- No Express.js overhead
- Minimal memory footprint
- Fast startup time
- Efficient JSON parsing
- Built-in request size limits

Perfect for development, testing, and lightweight production use cases.
