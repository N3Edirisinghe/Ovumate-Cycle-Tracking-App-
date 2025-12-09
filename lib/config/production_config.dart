import 'package:flutter/foundation.dart';

/// Production configuration for large-scale applications
class ProductionConfig {
  static final ProductionConfig _instance = ProductionConfig._internal();
  factory ProductionConfig() => _instance;
  ProductionConfig._internal();

  // Environment configuration
  static const String _environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
  static const bool _isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const bool _isStaging = bool.fromEnvironment('STAGING', defaultValue: false);
  
  // Performance configuration
  static const int _maxConcurrentOperations = int.fromEnvironment('MAX_CONCURRENT_OPS', defaultValue: 10);
  static const int _maxCacheSize = int.fromEnvironment('MAX_CACHE_SIZE', defaultValue: 1000);
  static const int _maxBatchSize = int.fromEnvironment('MAX_BATCH_SIZE', defaultValue: 100);
  static const Duration _operationTimeout = Duration(
    seconds: int.fromEnvironment('OPERATION_TIMEOUT_SECONDS', defaultValue: 30),
  );
  
  // Database configuration
  static const int _maxDatabaseConnections = int.fromEnvironment('MAX_DB_CONNECTIONS', defaultValue: 20);
  static const Duration _databaseTimeout = Duration(
    seconds: int.fromEnvironment('DB_TIMEOUT_SECONDS', defaultValue: 15),
  );
  static const int _maxQueryResults = int.fromEnvironment('MAX_QUERY_RESULTS', defaultValue: 10000);
  
  // Analytics configuration
  static const bool _enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
  static const bool _enableErrorReporting = bool.fromEnvironment('ENABLE_ERROR_REPORTING', defaultValue: true);
  static const Duration _analyticsFlushInterval = Duration(
    minutes: int.fromEnvironment('ANALYTICS_FLUSH_MINUTES', defaultValue: 5),
  );
  
  // Security configuration
  static const bool _enableEncryption = bool.fromEnvironment('ENABLE_ENCRYPTION', defaultValue: true);
  static const bool _enableCertificatePinning = bool.fromEnvironment('ENABLE_CERT_PINNING', defaultValue: true);
  static const Duration _sessionTimeout = Duration(
    hours: int.fromEnvironment('SESSION_TIMEOUT_HOURS', defaultValue: 24),
  );
  
  // Feature flags
  static const bool _enableAdvancedAnalytics = bool.fromEnvironment('ENABLE_ADVANCED_ANALYTICS', defaultValue: false);
  static const bool _enableRealTimeSync = bool.fromEnvironment('ENABLE_REALTIME_SYNC', defaultValue: false);
  static const bool _enableOfflineMode = bool.fromEnvironment('ENABLE_OFFLINE_MODE', defaultValue: true);
  static const bool _enablePushNotifications = bool.fromEnvironment('ENABLE_PUSH_NOTIFICATIONS', defaultValue: false);
  
  // Rate limiting
  static const int _maxRequestsPerMinute = int.fromEnvironment('MAX_REQUESTS_PER_MINUTE', defaultValue: 100);
  static const int _maxRequestsPerHour = int.fromEnvironment('MAX_REQUESTS_PER_HOUR', defaultValue: 1000);
  static const Duration _rateLimitWindow = Duration(
    minutes: int.fromEnvironment('RATE_LIMIT_WINDOW_MINUTES', defaultValue: 1),
  );
  
  // Monitoring configuration
  static const bool _enablePerformanceMonitoring = bool.fromEnvironment('ENABLE_PERF_MONITORING', defaultValue: true);
  static const bool _enableCrashReporting = bool.fromEnvironment('ENABLE_CRASH_REPORTING', defaultValue: true);
  static const Duration _healthCheckInterval = Duration(
    minutes: int.fromEnvironment('HEALTH_CHECK_MINUTES', defaultValue: 5),
  );
  
  // Logging configuration
  static const String _logLevel = String.fromEnvironment('LOG_LEVEL', defaultValue: 'info');
  static const bool _enableStructuredLogging = bool.fromEnvironment('ENABLE_STRUCTURED_LOGGING', defaultValue: true);
  static const int _maxLogFileSize = int.fromEnvironment('MAX_LOG_FILE_SIZE_MB', defaultValue: 100);
  static const int _maxLogFiles = int.fromEnvironment('MAX_LOG_FILES', defaultValue: 10);
  
  // API configuration
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://api.ovumate.com');
  static const Duration _apiTimeout = Duration(
    seconds: int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 30),
  );
  static const int _apiRetryAttempts = int.fromEnvironment('API_RETRY_ATTEMPTS', defaultValue: 3);
  static const Duration _apiRetryDelay = Duration(
    seconds: int.fromEnvironment('API_RETRY_DELAY_SECONDS', defaultValue: 1),
  );
  
  // Cache configuration
  static const Duration _defaultCacheExpiry = Duration(
    minutes: int.fromEnvironment('DEFAULT_CACHE_EXPIRY_MINUTES', defaultValue: 15),
  );
  static const Duration _longTermCacheExpiry = Duration(
    hours: int.fromEnvironment('LONG_TERM_CACHE_EXPIRY_HOURS', defaultValue: 24),
  );
  
  // User experience configuration
  static const Duration _splashScreenDuration = Duration(
    milliseconds: int.fromEnvironment('SPLASH_SCREEN_DURATION_MS', defaultValue: 2000),
  );
  static const bool _enableAnimations = bool.fromEnvironment('ENABLE_ANIMATIONS', defaultValue: true);
  static const bool _enableHapticFeedback = bool.fromEnvironment('ENABLE_HAPTIC_FEEDBACK', defaultValue: true);
  
  // Data retention
  static const Duration _dataRetentionPeriod = Duration(
    days: int.fromEnvironment('DATA_RETENTION_DAYS', defaultValue: 730), // 2 years
  );
  static const bool _enableDataCompression = bool.fromEnvironment('ENABLE_DATA_COMPRESSION', defaultValue: true);
  static const bool _enableDataBackup = bool.fromEnvironment('ENABLE_DATA_BACKUP', defaultValue: true);
  
  // Network configuration
  static const bool _enableNetworkOptimization = bool.fromEnvironment('ENABLE_NETWORK_OPTIMIZATION', defaultValue: true);
  static const bool _enableRequestCompression = bool.fromEnvironment('ENABLE_REQUEST_COMPRESSION', defaultValue: true);
  static const bool _enableResponseCompression = bool.fromEnvironment('ENABLE_RESPONSE_COMPRESSION', defaultValue: true);
  
  // Privacy configuration
  static const bool _enableDataAnonymization = bool.fromEnvironment('ENABLE_DATA_ANONYMIZATION', defaultValue: false);
  static const bool _enablePrivacyControls = bool.fromEnvironment('ENABLE_PRIVACY_CONTROLS', defaultValue: true);
  static const bool _enableConsentManagement = bool.fromEnvironment('ENABLE_CONSENT_MANAGEMENT', defaultValue: true);
  
  // Accessibility configuration
  static const bool _enableAccessibilityFeatures = bool.fromEnvironment('ENABLE_ACCESSIBILITY', defaultValue: true);
  static const bool _enableScreenReaderSupport = bool.fromEnvironment('ENABLE_SCREEN_READER', defaultValue: true);
  static const bool _enableHighContrastMode = bool.fromEnvironment('ENABLE_HIGH_CONTRAST', defaultValue: true);
  
  // Internationalization
  static const List<String> _supportedLanguages = ['en', 'si', 'ta']; // English, Sinhala, Tamil
  static const String _defaultLanguage = String.fromEnvironment('DEFAULT_LANGUAGE', defaultValue: 'en');
  static const bool _enableAutoLanguageDetection = bool.fromEnvironment('ENABLE_AUTO_LANGUAGE', defaultValue: true);
  
  // Testing configuration
  static const bool _enableTestMode = bool.fromEnvironment('ENABLE_TEST_MODE', defaultValue: false);
  static const bool _enableMockData = bool.fromEnvironment('ENABLE_MOCK_DATA', defaultValue: false);
  static const bool _enablePerformanceProfiling = bool.fromEnvironment('ENABLE_PERF_PROFILING', defaultValue: false);
  
  /// Get current environment
  String get environment => _environment;
  
  /// Check if running in production
  bool get isProduction => _isProduction;
  
  /// Check if running in staging
  bool get isStaging => _isStaging;
  
  /// Check if running in development
  bool get isDevelopment => !_isProduction && !_isStaging;
  
  /// Get performance configuration
  Map<String, dynamic> get performanceConfig => {
    'maxConcurrentOperations': _maxConcurrentOperations,
    'maxCacheSize': _maxCacheSize,
    'maxBatchSize': _maxBatchSize,
    'operationTimeout': _operationTimeout.inSeconds,
  };
  
  /// Get database configuration
  Map<String, dynamic> get databaseConfig => {
    'maxConnections': _maxDatabaseConnections,
    'timeout': _databaseTimeout.inSeconds,
    'maxQueryResults': _maxQueryResults,
  };
  
  /// Get analytics configuration
  Map<String, dynamic> get analyticsConfig => {
    'enabled': _enableAnalytics,
    'errorReporting': _enableErrorReporting,
    'flushInterval': _analyticsFlushInterval.inMinutes,
  };
  
  /// Get security configuration
  Map<String, dynamic> get securityConfig => {
    'encryption': _enableEncryption,
    'certificatePinning': _enableCertificatePinning,
    'sessionTimeout': _sessionTimeout.inHours,
  };
  
  /// Get feature flags
  Map<String, dynamic> get featureFlags => {
    'advancedAnalytics': _enableAdvancedAnalytics,
    'realTimeSync': _enableRealTimeSync,
    'offlineMode': _enableOfflineMode,
    'pushNotifications': _enablePushNotifications,
  };
  
  /// Get rate limiting configuration
  Map<String, dynamic> get rateLimitConfig => {
    'maxRequestsPerMinute': _maxRequestsPerMinute,
    'maxRequestsPerHour': _maxRequestsPerHour,
    'windowSize': _rateLimitWindow.inMinutes,
  };
  
  /// Get monitoring configuration
  Map<String, dynamic> get monitoringConfig => {
    'performanceMonitoring': _enablePerformanceMonitoring,
    'crashReporting': _enableCrashReporting,
    'healthCheckInterval': _healthCheckInterval.inMinutes,
  };
  
  /// Get logging configuration
  Map<String, dynamic> get loggingConfig => {
    'level': _logLevel,
    'structuredLogging': _enableStructuredLogging,
    'maxFileSize': _maxLogFileSize,
    'maxFiles': _maxLogFiles,
  };
  
  /// Get API configuration
  Map<String, dynamic> get apiConfig => {
    'baseUrl': _apiBaseUrl,
    'timeout': _apiTimeout.inSeconds,
    'retryAttempts': _apiRetryAttempts,
    'retryDelay': _apiRetryDelay.inSeconds,
  };
  
  /// Get cache configuration
  Map<String, dynamic> get cacheConfig => {
    'defaultExpiry': _defaultCacheExpiry.inMinutes,
    'longTermExpiry': _longTermCacheExpiry.inHours,
  };
  
  /// Get user experience configuration
  Map<String, dynamic> get uxConfig => {
    'splashScreenDuration': _splashScreenDuration.inMilliseconds,
    'animations': _enableAnimations,
    'hapticFeedback': _enableHapticFeedback,
  };
  
  /// Get data retention configuration
  Map<String, dynamic> get dataRetentionConfig => {
    'retentionPeriod': _dataRetentionPeriod.inDays,
    'compression': _enableDataCompression,
    'backup': _enableDataBackup,
  };
  
  /// Get network configuration
  Map<String, dynamic> get networkConfig => {
    'optimization': _enableNetworkOptimization,
    'requestCompression': _enableRequestCompression,
    'responseCompression': _enableResponseCompression,
  };
  
  /// Get privacy configuration
  Map<String, dynamic> get privacyConfig => {
    'dataAnonymization': _enableDataAnonymization,
    'privacyControls': _enablePrivacyControls,
    'consentManagement': _enableConsentManagement,
  };
  
  /// Get accessibility configuration
  Map<String, dynamic> get accessibilityConfig => {
    'enabled': _enableAccessibilityFeatures,
    'screenReader': _enableScreenReaderSupport,
    'highContrast': _enableHighContrastMode,
  };
  
  /// Get internationalization configuration
  Map<String, dynamic> get i18nConfig => {
    'supportedLanguages': _supportedLanguages,
    'defaultLanguage': _defaultLanguage,
    'autoDetection': _enableAutoLanguageDetection,
  };
  
  /// Get testing configuration
  Map<String, dynamic> get testingConfig => {
    'testMode': _enableTestMode,
    'mockData': _enableMockData,
    'performanceProfiling': _enablePerformanceProfiling,
  };
  
  /// Get all configuration as a map
  Map<String, dynamic> get allConfig => {
    'environment': environment,
    'performance': performanceConfig,
    'database': databaseConfig,
    'analytics': analyticsConfig,
    'security': securityConfig,
    'features': featureFlags,
    'rateLimit': rateLimitConfig,
    'monitoring': monitoringConfig,
    'logging': loggingConfig,
    'api': apiConfig,
    'cache': cacheConfig,
    'ux': uxConfig,
    'dataRetention': dataRetentionConfig,
    'network': networkConfig,
    'privacy': privacyConfig,
    'accessibility': accessibilityConfig,
    'i18n': i18nConfig,
    'testing': testingConfig,
  };
  
  /// Check if a feature is enabled
  bool isFeatureEnabled(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'advanced_analytics':
        return _enableAdvancedAnalytics;
      case 'realtime_sync':
        return _enableRealTimeSync;
      case 'offline_mode':
        return _enableOfflineMode;
      case 'push_notifications':
        return _enablePushNotifications;
      case 'test_mode':
        return _enableTestMode;
      case 'mock_data':
        return _enableMockData;
      default:
        return false;
    }
  }
  
  /// Get configuration value by key
  dynamic getConfigValue(String key) {
    final keys = key.split('.');
    dynamic current = allConfig;
    
    for (final k in keys) {
      if (current is Map && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }
    
    return current;
  }
  
  /// Validate configuration
  bool validateConfiguration() {
    try {
      // Check required configurations
      if (_maxConcurrentOperations <= 0) return false;
      if (_maxCacheSize <= 0) return false;
      if (_maxBatchSize <= 0) return false;
      if (_operationTimeout.inSeconds <= 0) return false;
      
      // Check database configurations
      if (_maxDatabaseConnections <= 0) return false;
      if (_databaseTimeout.inSeconds <= 0) return false;
      if (_maxQueryResults <= 0) return false;
      
      // Check rate limiting
      if (_maxRequestsPerMinute <= 0) return false;
      if (_maxRequestsPerHour <= 0) return false;
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Configuration validation failed: $e');
      }
      return false;
    }
  }
  
  /// Print configuration summary
  void printConfigurationSummary() {
    if (kDebugMode) {
      print('=== Production Configuration Summary ===');
      print('Environment: $environment');
      print('Production: $isProduction');
      print('Staging: $isStaging');
      print('Development: $isDevelopment');
      print('Max Concurrent Operations: $_maxConcurrentOperations');
      print('Max Cache Size: $_maxCacheSize');
      print('Max Batch Size: $_maxBatchSize');
      print('Operation Timeout: ${_operationTimeout.inSeconds}s');
      print('========================================');
    }
  }
}
