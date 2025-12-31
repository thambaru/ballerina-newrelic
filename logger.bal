import ballerina/http;

# Logger class for structured logging with New Relic integration
public isolated class Logger {
    private final LoggerConfig & readonly config;
    private final TraceContext & readonly defaultContext;
    private final http:Client? httpClient;
    
    # Initialize a new logger instance
    #
    # + config - Logger configuration
    # + httpClient - HTTP client for New Relic (optional)
    public isolated function init(LoggerConfig config, http:Client? httpClient = ()) {
        self.config = config.cloneReadOnly();
        self.defaultContext = generateTraceContext().cloneReadOnly();
        self.httpClient = httpClient;
    }
    
    # Log an INFO level message
    #
    # + message - Log message
    # + additionalFields - Additional fields to include in log
    # + context - Trace context (optional, will generate if not provided)
    public isolated function info(
        string message,
        map<json> additionalFields = {},
        TraceContext? context = ()
    ) {
        self.log(INFO, message, additionalFields, context);
    }
    
    # Log a DEBUG level message
    #
    # + message - Log message
    # + additionalFields - Additional fields to include in log
    # + context - Trace context (optional, will generate if not provided)
    public isolated function debug(
        string message,
        map<json> additionalFields = {},
        TraceContext? context = ()
    ) {
        self.log(DEBUG, message, additionalFields, context);
    }
    
    # Log a WARN level message
    #
    # + message - Log message
    # + additionalFields - Additional fields to include in log
    # + context - Trace context (optional, will generate if not provided)
    public isolated function warn(
        string message,
        map<json> additionalFields = {},
        TraceContext? context = ()
    ) {
        self.log(WARN, message, additionalFields, context);
    }
    
    # Log an ERROR level message
    #
    # + message - Log message
    # + err - Error object (optional)
    # + additionalFields - Additional fields to include in log
    # + context - Trace context (optional, will generate if not provided)
    public isolated function logError(
        string message,
        error? err = (),
        map<json> additionalFields = {},
        TraceContext? context = ()
    ) {
        self.logWithError(ERROR, message, err, additionalFields, context);
    }
    
    # Log a message with specified level
    #
    # + level - Log level
    # + message - Log message
    # + additionalFields - Additional fields to include in log
    # + context - Trace context (optional, will generate if not provided)
    isolated function log(
        LogLevel level,
        string message,
        map<json> additionalFields,
        TraceContext? context
    ) {
        self.logWithError(level, message, (), additionalFields, context);
    }
    
    # Log a message with error
    #
    # + level - Log level
    # + message - Log message
    # + err - Error object (optional)
    # + additionalFields - Additional fields to include in log
    # + context - Trace context (optional, will generate if not provided)
    isolated function logWithError(
        LogLevel level,
        string message,
        error? err,
        map<json> additionalFields,
        TraceContext? context
    ) {
        // Check if we should log this level
        if !shouldLog(self.config.logLevel, level) {
            return;
        }
        
        // Use provided context or default
        TraceContext traceContext = context ?: self.defaultContext;
        
        // Format log record
        string|error jsonLog = formatLogRecord(
            self.config,
            level,
            message,
            traceContext,
            additionalFields,
            err
        );
        
        if jsonLog is error {
            // Log formatting failed, emit error to stderr
            exportToStderr(string `[NewRelic] Failed to format log: ${jsonLog.message()}`);
            return;
        }
        
        // Export log safely
        safeExportLog(self.config, jsonLog, self.httpClient);
    }
    
    # Get logger configuration
    #
    # + return - Logger configuration (readonly)
    public isolated function getConfig() returns LoggerConfig {
        return self.config;
    }
}

# Initialize a new logger
#
# + config - Logger configuration
# + return - Logger instance or error
public isolated function initLogger(LoggerConfig config) returns Logger|ConfigurationError {
    // Validate configuration
    if config.serviceName.trim().length() == 0 {
        return error ConfigurationError("serviceName is required and cannot be empty");
    }
    
    // Enrich config with environment variables if not provided
    string envEnvironment = getEnv("ENVIRONMENT", "production");
    string envVersion = getEnv("VERSION", "");
    string envLicenseKey = getEnv("NEW_RELIC_LICENSE_KEY", "");
    string envAppName = getEnv("NEW_RELIC_APP_NAME", "");
    string envLogEndpoint = getEnv("NEW_RELIC_LOG_ENDPOINT", "");
    
    LoggerConfig enrichedConfig = {
        serviceName: config.serviceName,
        environment: config.environment ?: (envEnvironment == "" ? () : envEnvironment),
        logLevel: config.logLevel,
        host: config.host ?: getHostname(),
        version: config.version ?: (envVersion == "" ? () : envVersion),
        enableNewRelic: config.enableNewRelic,
        newRelicLicenseKey: config.newRelicLicenseKey ?: (envLicenseKey == "" ? () : envLicenseKey),
        newRelicAppName: config.newRelicAppName ?: (envAppName == "" ? () : envAppName),
        newRelicLogEndpoint: config.newRelicLogEndpoint ?: (envLogEndpoint == "" ? () : envLogEndpoint)
    };
    
    // Create HTTP client if New Relic is enabled
    http:Client? httpClient = ();
    if enrichedConfig.enableNewRelic && enrichedConfig.newRelicLicenseKey is string {
        string endpoint = enrichedConfig.newRelicLogEndpoint ?: "https://log-api.newrelic.com/log/v1";
        
        // Check for EU region if not explicitly configured
        if enrichedConfig.newRelicLogEndpoint is () && enrichedConfig.newRelicLicenseKey.toString().startsWith("eu") {
            endpoint = "https://log-api.eu.newrelic.com/log/v1";
        }
        
        do {
            httpClient = check new(endpoint);
        } on fail error e {
            return error ConfigurationError(string `Failed to initialize New Relic HTTP client: ${e.message()}`);
        }
    }
    
    return new Logger(enrichedConfig, httpClient);
}
