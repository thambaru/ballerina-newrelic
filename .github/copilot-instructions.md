## Project Overview

This repository contains a **Ballerina observability library** that provides:

* **Structured JSON logging**
* **Automatic trace & span context propagation**
* **Seamless New Relic integration**
* **Low-friction developer experience**

The package is designed for **backend and microservice applications** running in production environments.

---

## Package Identity

* **Organization:** `thambaru`
* **Package:** `newrelic`
* **Module path:** `thambaru/newrelic`

---

## Core Objectives

When generating or modifying code, ensure the library:

1. Produces **structured JSON logs**
2. Automatically injects **trace.id** and **span.id**
3. Works with **New Relic log & trace correlation**
4. Has **zero required runtime configuration** to get started
5. Avoids vendor lock-in beyond optional New Relic exporters

This library should enhance observability **without changing application logic**.

---

## Design Principles

Always prioritize:

* **Production safety**
* **Minimal overhead**
* **Explicit behavior**
* **Predictable output**
* **Cloud-native compatibility**

Avoid:

* Hidden magic
* Silent failures
* Heavy dependencies
* Application-level concerns

---

## New Relic Integration Scope

This library focuses on **log correlation**, not full APM.

### Supported Features (v1)

* Trace ID & Span ID injection
* JSON logs compatible with New Relic Logs
* Support for:

  * New Relic Infrastructure Agent
  * New Relic OpenTelemetry pipeline
* Environment-based configuration

### Out of Scope (Unless Explicitly Requested)

* Custom New Relic agents
* Metric exporters
* Custom dashboards
* Alert configuration

---

## Structured Log Format

All logs MUST be emitted as **JSON objects**.

### Required Fields

```json
{
  "timestamp": "RFC3339",
  "level": "INFO|WARN|ERROR|DEBUG",
  "message": "string",
  "service.name": "string",
  "trace.id": "string",
  "span.id": "string"
}
```

### Optional Fields

* `environment`
* `host`
* `version`
* `error.type`
* `error.message`
* `error.stack`
* Custom application fields

---

## Trace Context Rules

* Extract trace context from:

  * HTTP headers (`traceparent`, `tracestate`)
* Propagate context automatically
* Generate trace/span IDs when missing
* Never break incoming trace chains

Trace context handling must follow **W3C Trace Context** standards.

---

## Public API Guidelines

### Logger Initialization

```ballerina
import thambaru/newrelic;

newrelic:Logger logger = check newrelic:initLogger({
    serviceName: "order-service",
    environment: "production",
    logLevel: newrelic:INFO
});
```

Initialization should:

* Be explicit
* Be idempotent
* Fail fast if misconfigured

---

### Logging APIs

Provide simple level-based logging:

```ballerina
logger.info("Order created", { orderId: "123" });
logger.error("Payment failed", err);
```

Rules:

* Logging should never panic
* Errors must be serialized safely
* Additional fields must merge into the JSON payload

---

## Configuration Model

Configuration MUST be environment-driven.

### Environment Variables

* `NEW_RELIC_LICENSE_KEY`
* `NEW_RELIC_APP_NAME`
* `NEW_RELIC_LOG_ENDPOINT` (optional)
* `NEW_RELIC_ENABLED` (default: true)

Do NOT hardcode credentials or endpoints.

---

## Error Handling Rules

* Logging failures must **never crash applications**
* Errors during log export should:

  * Be swallowed
  * Optionally logged to stderr
* All public errors must be wrapped as:

```ballerina
public type NewRelicError distinct error;
```

---

## Internal Architecture Guidelines

Recommended structure:

```
newrelic/
 ├── logger.bal
 ├── formatter.bal
 ├── context.bal
 ├── exporter.bal
 ├── errors.bal
 ├── types.bal
 └── utils.bal
```

Responsibilities:

* `logger.bal` → public API
* `context.bal` → trace/span extraction
* `formatter.bal` → JSON structure
* `exporter.bal` → stdout / HTTP export
* `types.bal` → records & enums

---

## HTTP & Framework Integration

The library should:

* Integrate cleanly with `http:Listener`
* Extract trace context from incoming requests
* Attach trace context to outgoing requests (when possible)

Avoid framework-specific assumptions.

---

## Performance Requirements

Generated code must:

* Avoid blocking I/O
* Minimize allocations
* Reuse context objects where possible
* Be safe under high concurrency

Logging should not become a bottleneck.

---

## Testing Expectations

Tests should include:

* JSON format validation
* Trace ID propagation
* Missing trace header handling
* Error serialization
* New Relic compatibility checks

Prefer unit tests over integration tests.

---

## Documentation Expectations

All public APIs must include:

* Ballerina doc comments
* Clear examples
* New Relic setup instructions
* Sample log output

README examples must be **production-realistic**.

---

## Style Guidelines

* Follow official Ballerina formatting
* Use explicit types
* Avoid global mutable state
* Prefer records over maps
* Keep functions short and readable

---

## Security Considerations

* Never log secrets
* Mask fields named:

  * `password`
  * `token`
  * `secret`
  * `apiKey`
* Avoid PII in default logs

---

## Out of Scope (Unless Explicitly Requested)

Do NOT generate:

* Log storage solutions
* Metrics dashboards
* Tracing visualizations
* Agent installers
* CLI tools

---

## Success Criteria

Code generated for this repository should:

* Work out-of-the-box with New Relic
* Produce valid JSON logs
* Enable trace-log correlation
* Be safe for production workloads
* Be publishable on Ballerina Central

---

## Final Reminder

This library is **infrastructure-grade**, not application logic.

Favor:

* Reliability
* Transparency
* Simplicity

Over:

* Clever tricks
* Overengineering
* Hidden behavior