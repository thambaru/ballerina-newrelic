// Copyright (c) 2025, thambaru. All rights reserved.
//
// Ballerina New Relic Observability Library
//
// This module provides structured JSON logging with automatic trace context propagation
// and seamless New Relic integration for Ballerina applications.
//
// Features:
// - Structured JSON Logging: All logs emitted as JSON objects
// - Automatic Trace Context: W3C trace context extraction and propagation
// - New Relic Integration: Compatible with New Relic Logs and Distributed Tracing
// - Zero Configuration: Works out-of-the-box with sensible defaults
// - Production Ready: Safe error handling, no application crashes
//
// Quick Start:
//
// import ballerina/http;
// import thambaru/newrelic;
//
// public function main() returns error? {
//     // Initialize logger
//     newrelic:Logger logger = check newrelic:initLogger({
//         serviceName: "order-service",
//         environment: "production",
//         logLevel: newrelic:INFO
//     });
//
//     // Log messages
//     logger.info("Service started");
//     logger.info("Order created", { orderId: "12345", amount: 99.99 });
// }
