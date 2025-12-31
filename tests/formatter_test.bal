// Copyright (c) 2025, thambaru. All rights reserved.

import ballerina/test;

@test:Config {}
function testFormatBasicLogRecord() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    TraceContext context = {
        traceId: "abcdef1234567890abcdef1234567890",
        spanId: "1234567890abcdef",
        traceFlags: "01"
    };
    
    string jsonLog = check formatLogRecord(config, INFO, "Test message", context);
    
    // Verify it's valid JSON
    test:assertTrue(jsonLog.startsWith("{"), "Should be valid JSON");
    
    // Verify required fields are present
    test:assertTrue(jsonLog.includes("\"timestamp\""), "Should contain timestamp");
    test:assertTrue(jsonLog.includes("\"level\":\"INFO\""), "Should contain level");
    test:assertTrue(jsonLog.includes("\"message\":\"Test message\""), "Should contain message");
    test:assertTrue(jsonLog.includes("\"service.name\":\"test-service\""), "Should contain service name");
    test:assertTrue(jsonLog.includes("\"trace.id\":\"abcdef1234567890abcdef1234567890\""), "Should contain trace ID");
    test:assertTrue(jsonLog.includes("\"span.id\":\"1234567890abcdef\""), "Should contain span ID");
}

@test:Config {}
function testFormatLogWithAdditionalFields() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    TraceContext context = generateTraceContext();
    
    map<json> fields = {
        "orderId": "12345",
        "amount": 99.99,
        "customer": "john@example.com"
    };
    
    string jsonLog = check formatLogRecord(config, INFO, "Order created", context, fields);
    
    test:assertTrue(jsonLog.includes("\"orderId\":\"12345\""), "Should contain additional field");
    test:assertTrue(jsonLog.includes("\"amount\":99.99"), "Should contain numeric field");
}

@test:Config {}
function testMaskPasswordField() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    TraceContext context = generateTraceContext();
    
    map<json> fields = {
        "username": "john",
        "password": "secret123"
    };
    
    string jsonLog = check formatLogRecord(config, INFO, "User login", context, fields);
    
    test:assertTrue(jsonLog.includes("\"username\":\"john\""), "Username should not be masked");
    test:assertTrue(jsonLog.includes("\"password\":\"***MASKED***\""), "Password should be masked");
    test:assertFalse(jsonLog.includes("secret123"), "Password value should not appear");
}

@test:Config {}
function testMaskTokenField() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    TraceContext context = generateTraceContext();
    
    map<json> fields = {
        "apiToken": "abc123",
        "apiKey": "xyz789",
        "secret": "confidential"
    };
    
    string jsonLog = check formatLogRecord(config, INFO, "API call", context, fields);
    
    test:assertTrue(jsonLog.includes("***MASKED***"), "Sensitive fields should be masked");
    test:assertFalse(jsonLog.includes("abc123"), "Token should not appear");
    test:assertFalse(jsonLog.includes("xyz789"), "API key should not appear");
    test:assertFalse(jsonLog.includes("confidential"), "Secret should not appear");
}

@test:Config {}
function testFormatLogWithError() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    TraceContext context = generateTraceContext();
    
    error testError = error("Test error", message = "Something went wrong");
    
    string jsonLog = check formatLogRecord(config, ERROR, "Operation failed", context, {}, testError);
    
    test:assertTrue(jsonLog.includes("\"error.type\""), "Should contain error type");
    test:assertTrue(jsonLog.includes("\"error.message\""), "Should contain error message");
    test:assertTrue(jsonLog.includes("\"error.stack\""), "Should contain error stack");
}

@test:Config {}
function testFormatLogWithEnvironment() returns error? {
    LoggerConfig config = {
        serviceName: "test-service",
        environment: "production",
        host: "server-01",
        version: "1.0.0"
    };
    
    TraceContext context = generateTraceContext();
    
    string jsonLog = check formatLogRecord(config, INFO, "Test", context);
    
    test:assertTrue(jsonLog.includes("\"environment\":\"production\""), "Should contain environment");
    test:assertTrue(jsonLog.includes("\"host\":\"server-01\""), "Should contain host");
    test:assertTrue(jsonLog.includes("\"version\":\"1.0.0\""), "Should contain version");
}

@test:Config {}
function testLogLevels() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    TraceContext context = generateTraceContext();
    
    string debugLog = check formatLogRecord(config, DEBUG, "Debug message", context);
    test:assertTrue(debugLog.includes("\"level\":\"DEBUG\""));
    
    string infoLog = check formatLogRecord(config, INFO, "Info message", context);
    test:assertTrue(infoLog.includes("\"level\":\"INFO\""));
    
    string warnLog = check formatLogRecord(config, WARN, "Warn message", context);
    test:assertTrue(warnLog.includes("\"level\":\"WARN\""));
    
    string errorLog = check formatLogRecord(config, ERROR, "Error message", context);
    test:assertTrue(errorLog.includes("\"level\":\"ERROR\""));
}
