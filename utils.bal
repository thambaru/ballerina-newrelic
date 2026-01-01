import ballerina/os;


# Get environment variable with fallback
#
# + key - Environment variable key
# + defaultValue - Default value if not set
# + return - Environment variable value or default
public isolated function getEnv(string key, string defaultValue = "") returns string {
    string value = os:getEnv(key);
    return value != "" ? value : defaultValue;
}

# Get hostname
#
# + return - Hostname or "unknown"
public isolated function getHostname() returns string {
    // Try to get hostname from environment
    string hostname = getEnv("HOSTNAME", "");
    if hostname != "" {
        return hostname;
    }
    
    // Fallback to generic identifier
    return "unknown";
}

# Check if log level should be emitted
#
# + configuredLevel - Configured minimum log level
# + messageLevel - Message log level
# + return - True if message should be logged
public isolated function shouldLog(LogLevel configuredLevel, LogLevel messageLevel) returns boolean {
    int configuredLevelValue = getLevelValue(configuredLevel);
    int messageLevelValue = getLevelValue(messageLevel);
    
    return messageLevelValue >= configuredLevelValue;
}

# Get numeric value for log level
#
# + level - Log level
# + return - Numeric value (higher = more severe)
isolated function getLevelValue(LogLevel level) returns int {
    match level {
        DEBUG => {
            return 0;
        }
        INFO => {
            return 1;
        }
        WARN => {
            return 2;
        }
        ERROR => {
            return 3;
        }
    }
    return 0; // Should be unreachable
}
