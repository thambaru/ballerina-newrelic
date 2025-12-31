// Copyright (c) 2025, thambaru. All rights reserved.

import ballerina/test;

@test:Config {}
function testInitLoggerWithValidConfig() returns error? {
    LoggerConfig config = {
        serviceName: "test-service",
        environment: "development",
        logLevel: INFO
    };
    
    Logger logger = check initLogger(config);
    LoggerConfig retrievedConfig = logger.getConfig();
    
    test:assertEquals(retrievedConfig.serviceName, "test-service");
    test:assertEquals(retrievedConfig.environment, "development");
    test:assertEquals(retrievedConfig.logLevel, INFO);
}

@test:Config {}
function testInitLoggerWithEmptyServiceName() {
    LoggerConfig config = {
        serviceName: ""
    };
    
    Logger|ConfigurationError result = initLogger(config);
    
    test:assertTrue(result is ConfigurationError, "Should fail with empty service name");
}

@test:Config {}
function testLoggerInfoMethod() returns error? {
    LoggerConfig config = {
        serviceName: "test-service",
        logLevel: INFO
    };
    
    Logger logger = check initLogger(config);
    
    // This should not throw an error
    logger.info("Test info message");
    logger.info("Test with fields", { key: "value" });
}

@test:Config {}
function testLoggerDebugMethod() returns error? {
    LoggerConfig config = {
        serviceName: "test-service",
        logLevel: DEBUG
    };
    
    Logger logger = check initLogger(config);
    
    logger.debug("Test debug message");
    logger.debug("Test with fields", { debugInfo: "test" });
}

@test:Config {}
function testLoggerWarnMethod() returns error? {
    LoggerConfig config = {
        serviceName: "test-service",
        logLevel: WARN
    };
    
    Logger logger = check initLogger(config);
    
    logger.warn("Test warn message");
    logger.warn("Test with fields", { warning: "something" });
}

@test:Config {}
function testLoggerErrorMethod() returns error? {
    LoggerConfig config = {
        serviceName: "test-service",
        logLevel: ERROR
    };
    
    Logger logger = check initLogger(config);
    
    logger.logError("Test error message");
    
    error testError = error("Test error");
    logger.logError("Error with exception", testError);
}

@test:Config {}
function testLoggerWithCustomContext() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    Logger logger = check initLogger(config);
    
    TraceContext customContext = {
        traceId: "abcdef1234567890abcdef1234567890",
        spanId: "1234567890abcdef",
        traceFlags: "01"
    };
    
    // Should work with custom context
    logger.info("Test with custom context", {}, customContext);
}

@test:Config {}
function testLogLevelFiltering() returns error? {
    // Logger configured with WARN level
    LoggerConfig config = {
        serviceName: "test-service",
        logLevel: WARN
    };
    
    Logger logger = check initLogger(config);
    
    // These should not be logged (below WARN)
    logger.debug("This should not appear");
    logger.info("This should not appear either");
    
    // These should be logged
    logger.warn("This should appear");
    logger.logError("This should also appear");
    
    // Note: We can't easily verify what was/wasn't printed in unit tests,
    // but at least we verify the methods don't crash
}

@test:Config {}
function testLoggerIsIsolated() returns error? {
    LoggerConfig config = {
        serviceName: "concurrent-test-service"
    };
    
    Logger logger = check initLogger(config);
    
    // Simulate concurrent logging (Ballerina handles this safely)
    worker A {
        logger.info("Message from worker A");
    }
    
    worker B {
        logger.info("Message from worker B");
    }
    
    // Both workers should complete without errors
}

@test:Config {}
function testLoggerSafetyWithInvalidData() returns error? {
    LoggerConfig config = {
        serviceName: "test-service"
    };
    
    Logger logger = check initLogger(config);
    
    // Try logging with various data types
    logger.info("Test with null", { nullValue: () });
    logger.info("Test with nested", { nested: { value: "test" } });
    
    // Logger should handle these safely without crashing
}
