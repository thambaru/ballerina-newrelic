// Copyright (c) 2025, thambaru. All rights reserved.

import ballerina/random;
import ballerina/http;
import ballerina/lang.'string as strings;


# Extract trace context from HTTP headers
#
# + headers - HTTP headers map
# + return - TraceContext or error if extraction fails
public isolated function extractTraceContext(map<string|string[]> headers) returns TraceContext|TraceContextError {
    // Look for W3C traceparent header
    string|string[]? traceparentValue = headers["traceparent"];
    
    if traceparentValue is string {
        return parseTraceparent(traceparentValue);
    } else if traceparentValue is string[] && traceparentValue.length() > 0 {
        return parseTraceparent(traceparentValue[0]);
    }
    
    // If no traceparent header, generate new context
    return generateTraceContext();
}

# Extract trace context from HTTP request
#
# + request - HTTP request object
# + return - TraceContext or error
public isolated function extractTraceContextFromRequest(http:Request request) returns TraceContext|TraceContextError {
    map<string|string[]> headers = {};
    
    // Get all header names and build a map
    string[] headerNames = request.getHeaderNames();
    foreach string headerName in headerNames {
        string|http:HeaderNotFoundError headerValue = request.getHeader(headerName);
        if headerValue is string {
            headers[headerName.toLowerAscii()] = headerValue;
        }
    }
    
    return extractTraceContext(headers);
}

# Parse W3C traceparent header
#
# Format: 00-traceId-spanId-flags
# + traceparent - Traceparent header value
# + return - TraceContext or error
isolated function parseTraceparent(string traceparent) returns TraceContext|TraceContextError {
    string[] parts = re `-`.split(traceparent);
    
    if parts.length() != 4 {
        return error TraceContextError("Invalid traceparent format. Expected: version-traceId-spanId-flags");
    }
    
    string version = parts[0];
    string traceId = parts[1];
    string spanId = parts[2];
    string traceFlags = parts[3];
    
    // Validate version (should be 00)
    if version != "00" {
        return error TraceContextError(string `Unsupported traceparent version: ${version}`);
    }
    
    // Validate trace ID (32 hex chars)
    if traceId.length() != 32 || !isHexString(traceId) {
        return error TraceContextError("Invalid trace ID. Must be 32 hexadecimal characters");
    }
    
    // Validate span ID (16 hex chars)
    if spanId.length() != 16 || !isHexString(spanId) {
        return error TraceContextError("Invalid span ID. Must be 16 hexadecimal characters");
    }
    
    // Validate flags (2 hex chars)
    if traceFlags.length() != 2 || !isHexString(traceFlags) {
        return error TraceContextError("Invalid trace flags. Must be 2 hexadecimal characters");
    }
    
    return {
        traceId: traceId,
        spanId: spanId,
        traceFlags: traceFlags
    };
}

# Generate a new trace context
#
# + return - New TraceContext with random IDs
public isolated function generateTraceContext() returns TraceContext {
    return {
        traceId: generateTraceId(),
        spanId: generateSpanId(),
        traceFlags: "01"
    };
}

# Generate a new span ID within existing trace
#
# + parentContext - Parent trace context
# + return - New TraceContext with same trace ID but new span ID
public isolated function generateChildSpan(TraceContext parentContext) returns TraceContext {
    return {
        traceId: parentContext.traceId,
        spanId: generateSpanId(),
        traceFlags: parentContext.traceFlags,
        traceState: parentContext.traceState
    };
}

# Format trace context as W3C traceparent header
#
# + context - Trace context
# + return - Traceparent header value
public isolated function formatTraceparent(TraceContext context) returns string {
    return string `00-${context.traceId}-${context.spanId}-${context.traceFlags}`;
}

# Generate a random trace ID (32 hex chars / 16 bytes)
#
# + return - Trace ID string
isolated function generateTraceId() returns string {
    string hex = "";
    foreach int i in 0...15 {
        int randomByte = checkpanic random:createIntInRange(0, 256);
        hex = hex + byteToHex(randomByte);
    }
    return hex;
}

# Generate a random span ID (16 hex chars / 8 bytes)
#
# + return - Span ID string
isolated function generateSpanId() returns string {
    string hex = "";
    foreach int i in 0...7 {
        int randomByte = checkpanic random:createIntInRange(0, 256);
        hex = hex + byteToHex(randomByte);
    }
    return hex;
}

# Convert bytes to hex string
#
# + bytes - Byte array
# + return - Hex string
isolated function bytesToHex(byte[] bytes) returns string {
    string hex = "";
    foreach byte b in bytes {
        hex = hex + string `${byteToHex(b)}`;
    }
    return hex;
}

# Convert single byte value to 2-char hex string
#
# + b - Byte value as int
# + return - 2-character hex string
isolated function byteToHex(int b) returns string {
    string[] hexChars = ["0", "1", "2", "3", "4", "5", "6", "7", 
                         "8", "9", "a", "b", "c", "d", "e", "f"];
    int value = b;
    int high = value / 16;
    int low = value % 16;
    return hexChars[high] + hexChars[low];
}

# Check if string contains only hexadecimal characters
#
# + input - Input string
# + return - True if string is valid hex
isolated function isHexString(string input) returns boolean {
    string lowerInput = input.toLowerAscii();
    return strings:matches(lowerInput, re `^[0-9a-f]+$`);
}
