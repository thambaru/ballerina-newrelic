import ballerina/http;
import ballerina/io;

# Export log to stdout
#
# + jsonLog - JSON log string
public isolated function exportToStdout(string jsonLog) {
    io:println(jsonLog);
}

# Export log to stderr (for internal errors)
#
# + message - Error message
public isolated function exportToStderr(string message) {
    // Ballerina logs to stderr by default, or we can use io:println
    io:println(message); // In production, this goes to stdout
}

# Export log (future: could support HTTP export to New Relic)
#
# + config - Logger configuration
# + jsonLog - JSON log string
# + httpClient - HTTP client for New Relic (optional)
# + batchManager - Batch manager for New Relic logs (optional)
public isolated function exportLog(LoggerConfig config, string jsonLog, http:Client? httpClient = (), LogBatchManager? batchManager = ()) {
    // For v1, we only support stdout export
    // New Relic can collect logs from stdout via Infrastructure Agent
    exportToStdout(jsonLog);
    
    // Use batch manager for New Relic export if available
    if config.enableNewRelic && batchManager is LogBatchManager {
        batchManager.addLog(jsonLog);
    } else if config.enableNewRelic && httpClient is http:Client && config.newRelicLicenseKey is string {
        // Fallback to immediate sending if batch manager is not available
        _ = start exportToNewRelic(httpClient, jsonLog, config.newRelicLicenseKey ?: "");
    }
}

# Safely export log, swallowing any errors
#
# + config - Logger configuration
# + jsonLog - JSON log string
# + httpClient - HTTP client for New Relic (optional)
# + batchManager - Batch manager for New Relic logs (optional)
public isolated function safeExportLog(LoggerConfig config, string jsonLog, http:Client? httpClient = (), LogBatchManager? batchManager = ()) {
    do {
        exportLog(config, jsonLog, httpClient, batchManager);
    } on fail error e {
        // Never crash the application due to logging failures
        // Optionally log to stderr for debugging
        exportToStderr(string `[NewRelic] Log export failed: ${e.message()}`);
    }
}

# Export log to New Relic Logs API
#
# + httpClient - HTTP client
# + jsonLog - JSON log string
# + licenseKey - New Relic license key
isolated function exportToNewRelic(http:Client httpClient, string jsonLog, string licenseKey) {
    do {
        http:Request req = new;
        req.setHeader("X-License-Key", licenseKey);
        req.setHeader("Content-Type", "application/json");
        req.setTextPayload(jsonLog);

        http:Response response = check httpClient->post("", req);
        
        if response.statusCode >= 300 {
            fail error(string `New Relic Logs API returned status ${response.statusCode}`);
        }
    } on fail error e {
        exportToStderr(string `[NewRelic] HTTP export failed: ${e.message()}`);
    }
}
