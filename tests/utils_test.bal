// Copyright (c) 2025, thambaru. All rights reserved.

import ballerina/test;

@test:Config {}
function testShouldLogDebugLevel() {
    test:assertTrue(shouldLog(DEBUG, DEBUG));
    test:assertTrue(shouldLog(DEBUG, INFO));
    test:assertTrue(shouldLog(DEBUG, WARN));
    test:assertTrue(shouldLog(DEBUG, ERROR));
}

@test:Config {}
function testShouldLogInfoLevel() {
    test:assertFalse(shouldLog(INFO, DEBUG));
    test:assertTrue(shouldLog(INFO, INFO));
    test:assertTrue(shouldLog(INFO, WARN));
    test:assertTrue(shouldLog(INFO, ERROR));
}

@test:Config {}
function testShouldLogWarnLevel() {
    test:assertFalse(shouldLog(WARN, DEBUG));
    test:assertFalse(shouldLog(WARN, INFO));
    test:assertTrue(shouldLog(WARN, WARN));
    test:assertTrue(shouldLog(WARN, ERROR));
}

@test:Config {}
function testShouldLogErrorLevel() {
    test:assertFalse(shouldLog(ERROR, DEBUG));
    test:assertFalse(shouldLog(ERROR, INFO));
    test:assertFalse(shouldLog(ERROR, WARN));
    test:assertTrue(shouldLog(ERROR, ERROR));
}

@test:Config {}
function testGetEnvWithValue() {
    // Note: This test assumes the TEST_ENV variable is set
    // In a real test environment, you'd mock this
    string value = getEnv("PATH", "default");
    test:assertNotEquals(value, "default", "PATH should be set in environment");
}

@test:Config {}
function testGetEnvWithDefault() {
    string value = getEnv("NONEXISTENT_VAR_12345", "default-value");
    test:assertEquals(value, "default-value", "Should return default for missing var");
}

@test:Config {}
function testGetHostname() {
    string hostname = getHostname();
    test:assertNotEquals(hostname, "", "Hostname should not be empty");
}
