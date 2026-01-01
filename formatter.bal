import ballerina/time;

# Fields to mask in logs for security
final readonly & string[] MASKED_FIELDS = ["password", "token", "secret", "apiKey", "apikey", "api_key"];

# Format log record as JSON string
#
# + config - Logger configuration
# + level - Log level
# + message - Log message
# + context - Trace context
# + additionalFields - Additional fields to include
# + err - Error object (optional)
# + return - JSON string or error
public isolated function formatLogRecord(
    LoggerConfig config,
    LogLevel level,
    string message,
    TraceContext context,
    map<json> additionalFields = {},
    error? err = ()
) returns string|error {
    
    map<json> logRecord = {
        "timestamp": time:utcToString(time:utcNow()),
        "level": level.toString(),
        "message": message,
        "service.name": config.serviceName,
        "trace.id": context.traceId,
        "span.id": context.spanId
    };
    
    // Add optional config fields
    if config.environment is string {
        logRecord["environment"] = config.environment;
    }
    
    if config.host is string {
        logRecord["host"] = config.host;
    }
    
    if config.version is string {
        logRecord["version"] = config.version;
    }
    
    // Add error details if present
    if err is error {
        logRecord["error.type"] = err.message();
        logRecord["error.message"] = err.detail().toString();
        logRecord["error.stack"] = err.stackTrace().toString();
    }
    
    // Merge additional fields with masking
    map<json> maskedFields = maskSensitiveFields(additionalFields);
    foreach [string, json] [key, value] in maskedFields.entries() {
        logRecord[key] = value;
    }
    
    return logRecord.toJsonString();
}

# Mask sensitive fields in a map
#
# + fields - Input fields
# + return - Fields with sensitive data masked
isolated function maskSensitiveFields(map<json> fields) returns map<json> {
    map<json> masked = {};
    
    foreach [string, json] [key, value] in fields.entries() {
        if shouldMaskField(key) {
            masked[key] = "***MASKED***";
        } else if value is map<json> {
            // Recursively mask nested objects
            masked[key] = maskSensitiveFields(value);
        } else {
            masked[key] = value;
        }
    }
    
    return masked;
}

# Check if field should be masked
#
# + fieldName - Field name to check
# + return - True if field should be masked
isolated function shouldMaskField(string fieldName) returns boolean {
    string lowerFieldName = fieldName.toLowerAscii();
    
    foreach string maskedField in MASKED_FIELDS {
        if lowerFieldName.includes(maskedField) {
            return true;
        }
    }
    
    return false;
}

# Serialize error safely for logging
#
# + err - Error object
# + return - Map representation of error
public isolated function serializeError(error err) returns map<json> {
    return {
        "error.type": err.message(),
        "error.message": err.detail().toString(),
        "error.stack": err.stackTrace().toString()
    };
}
