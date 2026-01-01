# New Relic library error type
public type NewRelicError distinct error;

# Error for invalid configuration
public type ConfigurationError distinct NewRelicError;

# Error for trace context operations
public type TraceContextError distinct NewRelicError;

# Error for logging operations
public type LoggingError distinct NewRelicError;

# Error for export operations
public type ExportError distinct NewRelicError;
