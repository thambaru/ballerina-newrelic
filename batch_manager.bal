import ballerina/http;
import ballerina/time;
import ballerina/lang.runtime;
import ballerina/io;

# Log batch manager for lazy-sending logs to New Relic
public isolated class LogBatchManager {
    private final LoggerConfig & readonly config;
    private final http:Client httpClient;
    private final string licenseKey;
    private string[] logBuffer = [];
    private int lastFlushTime = 0;
    private boolean isShutdown = false;
    
    # Initialize batch manager
    #
    # + config - Logger configuration
    # + httpClient - HTTP client for New Relic
    # + licenseKey - New Relic license key
    public isolated function init(LoggerConfig config, http:Client httpClient, string licenseKey) {
        self.config = config.cloneReadOnly();
        self.httpClient = httpClient;
        self.licenseKey = licenseKey;
        self.lastFlushTime = time:utcNow()[0];
        
        // Start periodic flush if batching is enabled
        if config.enableBatching {
            _ = start self.periodicFlush();
        }
    }
    
    # Add log to batch
    #
    # + jsonLog - JSON log string
    public isolated function addLog(string jsonLog) {
        boolean shouldFlush = false;
        boolean shouldSendSingle = false;
        
        lock {
            if self.isShutdown {
                return;
            }
            
            self.logBuffer.push(jsonLog);
            
            // Check if we need to flush due to batch size
            if self.config.enableBatching && self.logBuffer.length() >= self.config.batchSize {
                shouldFlush = true;
            } else if !self.config.enableBatching {
                // If batching is disabled, send immediately
                shouldSendSingle = true;
            }
        }
        
        if shouldFlush {
            _ = start self.flushLogs();
        } else if shouldSendSingle {
            _ = start self.sendSingleLog(jsonLog);
        }
    }
    
    # Flush all pending logs
    public isolated function flushPendingLogs() {
        _ = start self.flushLogs();
    }
    
    # Shutdown the batch manager
    public isolated function shutdownManager() {
        lock {
            self.isShutdown = true;
        }
        self.flushPendingLogs();
    }
    
    # Periodic flush worker
    isolated function periodicFlush() {
        boolean shouldContinue = true;
        
        while shouldContinue {
            decimal sleepTime = <decimal>self.config.flushIntervalMs / 1000.0;
            runtime:sleep(sleepTime);
            
            boolean shouldFlush = false;
            
            lock {
                shouldContinue = !self.isShutdown;
                int currentTime = time:utcNow()[0];
                if currentTime - self.lastFlushTime >= self.config.flushIntervalMs / 1000 && 
                   self.logBuffer.length() > 0 {
                    shouldFlush = true;
                }
            }
            
            if shouldFlush {
                _ = start self.flushLogs();
            }
        }
    }
    
    # Flush logs to New Relic
    isolated function flushLogs() {
        string[] logsToSend = [];
        
        lock {
            if self.logBuffer.length() == 0 {
                return;
            }
            
            logsToSend = self.logBuffer.clone();
            self.logBuffer = [];
            self.lastFlushTime = time:utcNow()[0];
        }
        
        if logsToSend.length() > 0 {
            self.sendBatchLogs(logsToSend);
        }
    }
    
    # Send batch of logs to New Relic
    #
    # + logs - Array of JSON log strings
    isolated function sendBatchLogs(string[] logs) {
        do {
            // Create batch payload - New Relic expects an array of log objects
            string batchPayload = "[" + string:'join(",", ...logs) + "]";
            
            http:Request req = new;
            req.setHeader("X-License-Key", self.licenseKey);
            req.setHeader("Content-Type", "application/json");
            req.setTextPayload(batchPayload);

            http:Response response = check self.httpClient->post("", req);
            
            if response.statusCode >= 300 {
                fail error(string `New Relic Logs API returned status ${response.statusCode}`);
            }
        } on fail error e {
            logToStderr(string `[NewRelic] Batch export failed (${logs.length()} logs): ${e.message()}`);
        }
    }
    
    # Send single log to New Relic (when batching is disabled)
    #
    # + jsonLog - JSON log string
    isolated function sendSingleLog(string jsonLog) {
        do {
            http:Request req = new;
            req.setHeader("X-License-Key", self.licenseKey);
            req.setHeader("Content-Type", "application/json");
            req.setTextPayload(jsonLog);

            http:Response response = check self.httpClient->post("", req);
            
            if response.statusCode >= 300 {
                fail error(string `New Relic Logs API returned status ${response.statusCode}`);
            }
        } on fail error e {
            logToStderr(string `[NewRelic] Single log export failed: ${e.message()}`);
        }
    }
}

# Export log to stderr (for internal errors)
#
# + message - Error message
isolated function logToStderr(string message) {
    io:println(message);
}