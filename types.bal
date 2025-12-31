// Copyright (c) 2025, thambaru. All rights reserved.

# Log level enumeration
public enum LogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR
}

# Logger configuration record
#
# + serviceName - Name of the service (required)
# + environment - Deployment environment (optional)
# + logLevel - Minimum log level to emit (default: INFO)
# + host - Host identifier (optional, defaults to hostname)
# + version - Service version (optional)
# + enableNewRelic - Enable New Relic integration (default: true)
# + newRelicLicenseKey - New Relic license key (optional, can be set via env)
# + newRelicAppName - New Relic application name (optional, can be set via env)
# + newRelicLogEndpoint - New Relic log endpoint (optional)
public type LoggerConfig record {|
    string serviceName;
    string? environment = ();
    LogLevel logLevel = INFO;
    string? host = ();
    string? version = ();
    boolean enableNewRelic = true;
    string? newRelicLicenseKey = ();
    string? newRelicAppName = ();
    string? newRelicLogEndpoint = ();
|};

# Trace context record
#
# + traceId - W3C trace ID (32 hex chars)
# + spanId - W3C span ID (16 hex chars)
# + traceFlags - W3C trace flags (2 hex chars)
# + traceState - W3C trace state (optional)
public type TraceContext record {|
    string traceId;
    string spanId;
    string traceFlags = "01";
    string? traceState = ();
|};

# Structured log record
#
# + timestamp - RFC3339 timestamp
# + level - Log level
# + message - Log message
# + service\.name - Service name
# + trace\.id - Trace ID
# + span\.id - Span ID
# + environment - Deployment environment
# + host - Host identifier
# + version - Service version
# + error\.type - Error type (when logging errors)
# + error\.message - Error message
# + error\.stack - Error stack trace
public type LogRecord record {|
    string timestamp;
    string level;
    string message;
    string 'service\.name;
    string 'trace\.id;
    string 'span\.id;
    string? environment;
    string? host;
    string? version;
    string? 'error\.type;
    string? 'error\.message;
    string? 'error\.stack;
    map<json>...;
|};
