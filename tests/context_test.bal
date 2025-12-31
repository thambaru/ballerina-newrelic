// Copyright (c) 2025, thambaru. All rights reserved.

import ballerina/test;

@test:Config {}
function testGenerateTraceContext() {
    TraceContext context = generateTraceContext();
    
    // Verify trace ID is 32 hex chars
    test:assertEquals(context.traceId.length(), 32, "Trace ID should be 32 characters");
    
    // Verify span ID is 16 hex chars
    test:assertEquals(context.spanId.length(), 16, "Span ID should be 16 characters");
    
    // Verify flags
    test:assertEquals(context.traceFlags, "01", "Trace flags should be 01");
}

@test:Config {}
function testGenerateChildSpan() {
    TraceContext parentContext = {
        traceId: "abcdef1234567890abcdef1234567890",
        spanId: "1234567890abcdef",
        traceFlags: "01"
    };
    
    TraceContext childContext = generateChildSpan(parentContext);
    
    // Child should have same trace ID
    test:assertEquals(childContext.traceId, parentContext.traceId, "Child should inherit trace ID");
    
    // Child should have different span ID
    test:assertNotEquals(childContext.spanId, parentContext.spanId, "Child should have new span ID");
    
    // Flags should be inherited
    test:assertEquals(childContext.traceFlags, parentContext.traceFlags, "Child should inherit flags");
}

@test:Config {}
function testFormatTraceparent() {
    TraceContext context = {
        traceId: "abcdef1234567890abcdef1234567890",
        spanId: "1234567890abcdef",
        traceFlags: "01"
    };
    
    string traceparent = formatTraceparent(context);
    
    test:assertEquals(
        traceparent,
        "00-abcdef1234567890abcdef1234567890-1234567890abcdef-01",
        "Traceparent format should be correct"
    );
}

@test:Config {}
function testParseValidTraceparent() returns error? {
    string traceparent = "00-abcdef1234567890abcdef1234567890-1234567890abcdef-01";
    
    TraceContext context = check extractTraceContext({"traceparent": traceparent});
    
    test:assertEquals(context.traceId, "abcdef1234567890abcdef1234567890");
    test:assertEquals(context.spanId, "1234567890abcdef");
    test:assertEquals(context.traceFlags, "01");
}

@test:Config {}
function testParseInvalidTraceparentFormat() {
    string traceparent = "invalid-format";
    
    TraceContext|TraceContextError result = extractTraceContext({"traceparent": traceparent});
    
    test:assertTrue(result is TraceContextError, "Should return error for invalid format");
}

@test:Config {}
function testParseInvalidTraceId() {
    // Trace ID too short
    string traceparent = "00-abcdef-1234567890abcdef-01";
    
    TraceContext|TraceContextError result = extractTraceContext({"traceparent": traceparent});
    
    test:assertTrue(result is TraceContextError, "Should return error for invalid trace ID");
}

@test:Config {}
function testParseInvalidSpanId() {
    // Span ID too short
    string traceparent = "00-abcdef1234567890abcdef1234567890-abcdef-01";
    
    TraceContext|TraceContextError result = extractTraceContext({"traceparent": traceparent});
    
    test:assertTrue(result is TraceContextError, "Should return error for invalid span ID");
}

@test:Config {}
function testExtractMissingTraceparent() returns error? {
    // When traceparent is missing, should generate new context
    TraceContext context = check extractTraceContext({});
    
    test:assertEquals(context.traceId.length(), 32, "Should generate 32-char trace ID");
    test:assertEquals(context.spanId.length(), 16, "Should generate 16-char span ID");
}

@test:Config {}
function testRoundTripTraceparent() returns error? {
    // Generate context, format it, parse it back
    TraceContext original = generateTraceContext();
    string traceparent = formatTraceparent(original);
    TraceContext parsed = check extractTraceContext({"traceparent": traceparent});
    
    test:assertEquals(parsed.traceId, original.traceId);
    test:assertEquals(parsed.spanId, original.spanId);
    test:assertEquals(parsed.traceFlags, original.traceFlags);
}
