# Ballerina New Relic Observability Library

<a href="https://ballerina.io/"><img src="https://img.shields.io/badge/ballerina-2201.13.1-blue"></a>
<a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"></a>

A production-ready Ballerina library that provides structured JSON logging with automatic trace context propagation and seamless New Relic integration.

## Features

- ✅ **Structured JSON Logging** - All logs emitted as JSON objects
- 🔗 **Automatic Trace Context** - W3C trace context extraction and propagation
- 📊 **New Relic Integration** - Compatible with New Relic Logs and Distributed Tracing
- ⚡ **Zero Configuration** - Works out-of-the-box with sensible defaults
- 🛡️ **Production Ready** - Safe error handling, never crashes your application
- 🔒 **Security First** - Automatic masking of sensitive fields (passwords, tokens, secrets)
- 🚀 **Performance Optimized** - Minimal overhead, safe under high concurrency
- 📦 **Lazy-Sending** - Intelligent batching reduces New Relic API calls and improves performance

## Installation

Add the following dependency to your `Ballerina.toml`:

```toml
[[dependency]]
org = "thambaru"
name = "newrelic"
version = "0.1.0"
```

Or pull the package directly:

```bash
bal pull thambaru/newrelic
```

## Quick Start

### Basic Usage

```ballerina
import ballerina/http;
import thambaru/newrelic;

public function main() returns error? {
    // Initialize logger
    newrelic:Logger logger = check newrelic:initLogger({
        serviceName: "order-service",
        environment: "production",
        logLevel: newrelic:INFO
    });

    // Log messages
    logger.info("Service started");
    logger.info("Order created", { orderId: "12345", amount: 99.99 });
    logger.warn("High memory usage", { memoryPercent: 85 });
    
    error err = error("Payment gateway timeout");
    logger.logError("Payment failed", err, { orderId: "12345" });
}
```

### HTTP Service with Trace Context

```ballerina
import ballerina/http;
import thambaru/newrelic;

// Initialize logger once
final newrelic:Logger logger = check newrelic:initLogger({
    serviceName: "order-api",
    environment: "production"
});

service /api on new http:Listener(8080) {
    
    resource function post orders(http:Request req, @http:Payload json payload) returns json|error {
        // Extract trace context from incoming request
        newrelic:TraceContext context = check newrelic:extractTraceContextFromRequest(req);
        
        // Log with context - trace ID will be correlated in New Relic
        logger.info("Processing order", { 
            amount: check payload.amount 
        }, context);
        
        // Your business logic here
        
        logger.info("Order completed", { orderId: "123" }, context);
        
        return { status: "success", orderId: "123" };
    }
}
```

### Propagating Trace Context to Downstream Services

```ballerina
import ballerina/http;
import thambaru/newrelic;

public function callDownstreamService(newrelic:TraceContext context) returns error? {
    http:Client orderClient = check new ("http://order-service:8080");
    
    // Create child span for downstream call
    newrelic:TraceContext childContext = newrelic:generateChildSpan(context);
    
    // Add traceparent header
    http:Request req = new;
    req.setHeader("traceparent", newrelic:formatTraceparent(childContext));
    
    json response = check orderClient->post("/orders", req);
    
    logger.info("Downstream call completed", {}, childContext);
}
```

## Configuration

### Logger Configuration

```ballerina
public type LoggerConfig record {|
    string serviceName;              // Required: Service name
    string? environment = ();        // Optional: e.g., "production", "staging"
    LogLevel logLevel = INFO;        // Minimum log level (DEBUG, INFO, WARN, ERROR)
    string? host = ();               // Optional: Host identifier
    string? version = ();            // Optional: Service version
    boolean enableNewRelic = true;   // Enable New Relic features
    string? newRelicLicenseKey = (); // New Relic license key
    string? newRelicAppName = ();    // New Relic app name
    string? newRelicLogEndpoint = ();// New Relic log endpoint
    int batchSize = 100;             // Batch size for New Relic logs (default: 100)
    int flushIntervalMs = 5000;      // Flush interval in milliseconds (default: 5000)
    boolean enableBatching = true;   // Enable log batching (default: true)
|};
```

### Lazy-Sending Configuration

The library implements intelligent batching to reduce API calls to New Relic:

- **Batch Size**: Logs are collected and sent in batches (default: 100 logs)
- **Flush Interval**: Batches are automatically flushed every 5 seconds (default)
- **Immediate Mode**: Disable batching for immediate sending (set `enableBatching: false`)

```ballerina
// High-throughput service with large batches
newrelic:Logger logger = check newrelic:initLogger({
    serviceName: "high-volume-service",
    batchSize: 500,           // Send 500 logs at once
    flushIntervalMs: 10000,   // Flush every 10 seconds
    enableBatching: true
});

// Low-latency service with immediate sending
newrelic:Logger logger = check newrelic:initLogger({
    serviceName: "real-time-service",
    enableBatching: false     // Send each log immediately
});
```

### Environment Variables

Configuration values can be provided via environment variables:

- `NEW_RELIC_LICENSE_KEY` - Your New Relic license key
- `NEW_RELIC_APP_NAME` - Application name in New Relic
- `NEW_RELIC_LOG_ENDPOINT` - Custom log endpoint (optional)
- `NEW_RELIC_ENABLED` - Enable/disable New Relic (default: true)
- `ENVIRONMENT` - Deployment environment (default: "production")
- `VERSION` - Application version

Environment variables are automatically used if not provided in code.

## Log Format

All logs are emitted as JSON objects with the following structure:

```json
{
  "timestamp": "2025-12-30T12:16:31.123Z",
  "level": "INFO",
  "message": "Order created",
  "service.name": "order-service",
  "trace.id": "abcdef1234567890abcdef1234567890",
  "span.id": "1234567890abcdef",
  "environment": "production",
  "host": "server-01",
  "version": "1.0.0",
  "orderId": "12345",
  "amount": 99.99
}
```

### Required Fields

- `timestamp` - RFC3339 timestamp
- `level` - Log level (DEBUG, INFO, WARN, ERROR)
- `message` - Log message
- `service.name` - Service name
- `trace.id` - W3C trace ID (32 hex characters)
- `span.id` - W3C span ID (16 hex characters)

### Optional Fields

- `environment` - Deployment environment
- `host` - Host identifier
- `version` - Service version
- `error.type` - Error type (when logging errors)
- `error.message` - Error message
- `error.stack` - Error stack trace
- Custom application fields

## Security

The library automatically masks sensitive fields in logs:

- `password`
- `token`
- `secret`
- `apiKey` (any variation: apikey, api_key)

Masked values appear as `***MASKED***` in logs.

```ballerina
// Sensitive data is automatically masked
logger.info("User login", { 
    username: "john",
    password: "secret123"  // Will be masked
});

// Output: {"username":"john","password":"***MASKED***",...}
```

## New Relic Integration

### Lazy-Sending for Performance

The library implements intelligent batching to optimize performance and reduce API calls:

**How it works:**
1. **Batching**: Logs are collected in memory until batch size is reached (default: 100 logs)
2. **Timer-based flushing**: Batches are automatically sent every 5 seconds (configurable)
3. **Immediate mode**: Disable batching for real-time requirements
4. **Graceful shutdown**: All pending logs are flushed when the logger is shutdown

**Benefits:**
- 📈 **Reduced API calls**: 100x fewer HTTP requests to New Relic
- ⚡ **Better performance**: Lower latency for your application
- 💰 **Cost optimization**: Fewer API calls may reduce costs
- 🛡️ **Reliability**: Built-in retry and error handling

```ballerina
// Example: Configure batching for your use case
newrelic:Logger logger = check newrelic:initLogger({
    serviceName: "my-service",
    batchSize: 50,           // Send 50 logs at once
    flushIntervalMs: 3000,   // Flush every 3 seconds
    enableBatching: true     // Enable batching (default)
});

// For graceful shutdown, always flush pending logs
public function gracefulShutdown() {
    logger.flushLogs();      // Flush any pending logs
    logger.shutdownLogger(); // Stop batch manager
}
```

### Setup with New Relic Infrastructure Agent

1. Install the New Relic Infrastructure Agent on your host
2. Configure your Ballerina app to log to stdout (default behavior)
3. The agent will automatically collect and forward logs to New Relic

```bash
# Set environment variables
export NEW_RELIC_LICENSE_KEY="your-license-key"
export NEW_RELIC_APP_NAME="order-service"

# Run your Ballerina service
bal run
```

### Setup with OpenTelemetry

The library uses W3C trace context standard, making it compatible with OpenTelemetry:

```ballerina
// Trace context is automatically extracted from incoming requests
// and propagated to downstream services
```

### Viewing Logs in New Relic

1. Navigate to **Logs** in New Relic
2. Filter by `service.name` or `trace.id`
3. Trace-to-log correlation is automatic when using the same trace ID

## API Reference

### Logger Methods

```ballerina
# Log an INFO level message
logger.info(message, additionalFields?, context?);

# Log a DEBUG level message
logger.debug(message, additionalFields?, context?);

# Log a WARN level message
logger.warn(message, additionalFields?, context?);

# Log an ERROR level message
logger.logError(message, error?, additionalFields?, context?);

# Flush pending logs (useful for graceful shutdown)
logger.flushLogs();

# Shutdown logger and flush all pending logs
logger.shutdownLogger();
```

### Trace Context Functions

```ballerina
# Extract trace context from HTTP request
newrelic:extractTraceContextFromRequest(request) returns TraceContext|error

# Extract trace context from headers map
newrelic:extractTraceContext(headers) returns TraceContext|error

# Generate new trace context
newrelic:generateTraceContext() returns TraceContext

# Generate child span
newrelic:generateChildSpan(parentContext) returns TraceContext

# Format trace context as traceparent header
newrelic:formatTraceparent(context) returns string
```

## Testing

Run the test suite:

```bash
bal test
```

Tests cover:
- ✅ JSON format validation
- ✅ Trace ID propagation
- ✅ Missing trace header handling
- ✅ Error serialization
- ✅ Field masking
- ✅ Log level filtering
- ✅ Concurrent safety

## Design Principles

- **Production Safety** - Logging failures never crash the application
- **Minimal Overhead** - Optimized for high-throughput services
- **Explicit Behavior** - No hidden magic, predictable output
- **Cloud Native** - Compatible with containerized environments
- **Standards Based** - Follows W3C Trace Context specification

## Requirements

- Ballerina 2201.13.1 or later
- No external dependencies required for basic usage

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.

## Support

For issues and questions:
- GitHub Issues: [Create an issue](https://github.com/thambaru/newrelic/issues)
- Documentation: [Ballerina Central](https://central.ballerina.io/)

## Roadmap

- [ ] Custom metric support
- [ ] Performance metrics
- [ ] Sampling configuration

## Changelog

### v0.1.0

- Initial release
- Structured JSON logging
- W3C trace context support
- New Relic compatibility
- New Relic log export with async exporting
- Intelligent batching for performance optimization
- Automatic field masking
- Production-ready error handling
