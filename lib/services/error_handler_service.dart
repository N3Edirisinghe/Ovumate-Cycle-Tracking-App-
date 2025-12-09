import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ovumate/services/analytics_service.dart';

/// Comprehensive error handling service for production environments
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  static const String _errorLogFileName = 'error_logs.json';
  static const int _maxErrorLogs = 1000;
  static const Duration _errorReportInterval = Duration(minutes: 10);
  
  final List<ErrorLog> _errorLogs = [];
  Timer? _errorReportTimer;
  bool _isInitialized = false;
  final AnalyticsService _analytics = AnalyticsService();
  
  /// Initialize error handling service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _startErrorReportingTimer();
    await _loadPersistedErrors();
    _setupGlobalErrorHandlers();
    _isInitialized = true;
    
    if (kDebugMode) {
      print('Error handling service initialized');
    }
  }
  
  /// Setup global error handlers
  void _setupGlobalErrorHandlers() {
    // Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // Platform channel error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };
    
    // Zone error handling
    runZonedGuarded(() {
      // App runs in this zone
    }, (error, stack) {
      _handleZoneError(error, stack);
    });
  }
  
  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    final errorLog = ErrorLog(
      errorType: 'flutter_error',
      errorMessage: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      severity: _determineSeverity(details.exception),
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );
    
    _addErrorLog(errorLog);
    _reportErrorToAnalytics(errorLog);
    
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack Trace: ${details.stack}');
    }
  }
  
  /// Handle platform errors
  void _handlePlatformError(Object error, StackTrace stack) {
    final errorLog = ErrorLog(
      errorType: 'platform_error',
      errorMessage: error.toString(),
      stackTrace: stack.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      severity: _determineSeverity(error),
      context: {
        'platform': Platform.operatingSystem,
        'platformVersion': Platform.operatingSystemVersion,
      },
    );
    
    _addErrorLog(errorLog);
    _reportErrorToAnalytics(errorLog);
    
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack Trace: $stack');
    }
  }
  
  /// Handle zone errors
  void _handleZoneError(Object error, StackTrace stack) {
    final errorLog = ErrorLog(
      errorType: 'zone_error',
      errorMessage: error.toString(),
      stackTrace: stack.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      severity: _determineSeverity(error),
      context: {
        'zone': 'main_zone',
      },
    );
    
    _addErrorLog(errorLog);
    _reportErrorToAnalytics(errorLog);
    
    if (kDebugMode) {
      print('Zone Error: $error');
      print('Stack Trace: $stack');
    }
  }
  
  /// Handle custom errors
  void handleCustomError({
    required String errorType,
    required String errorMessage,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? userId,
  }) {
    final errorLog = ErrorLog(
      errorType: errorType,
      errorMessage: errorMessage,
      stackTrace: stackTrace?.toString(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
      severity: _determineSeverity(errorMessage),
      context: context,
      userId: userId,
    );
    
    _addErrorLog(errorLog);
    _reportErrorToAnalytics(errorLog);
    
    if (kDebugMode) {
      print('Custom Error: $errorType - $errorMessage');
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
    }
  }
  
  /// Handle network errors
  void handleNetworkError({
    required String operation,
    required String errorMessage,
    int? statusCode,
    String? url,
    Map<String, dynamic>? response,
    String? userId,
  }) {
    final errorLog = ErrorLog(
      errorType: 'network_error',
      errorMessage: errorMessage,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      severity: _determineNetworkErrorSeverity(statusCode),
      context: {
        'operation': operation,
        'status_code': statusCode,
        'url': url,
        'response': response,
      },
      userId: userId,
    );
    
    _addErrorLog(errorLog);
    _reportErrorToAnalytics(errorLog);
  }
  
  /// Handle database errors
  void handleDatabaseError({
    required String operation,
    required String errorMessage,
    String? table,
    String? query,
    Map<String, dynamic>? context,
    String? userId,
  }) {
    final errorLog = ErrorLog(
      errorType: 'database_error',
      errorMessage: errorMessage,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      severity: _determineSeverity(errorMessage),
      context: {
        'operation': operation,
        'table': table,
        'query': query,
        ...?context,
      },
      userId: userId,
    );
    
    _addErrorLog(errorLog);
    _reportErrorToAnalytics(errorLog);
  }
  
  /// Determine error severity
  ErrorSeverity _determineSeverity(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('crash') || 
        errorString.contains('fatal') || 
        errorString.contains('exception')) {
      return ErrorSeverity.critical;
    } else if (errorString.contains('error') || 
               errorString.contains('failed') || 
               errorString.contains('invalid')) {
      return ErrorSeverity.error;
    } else if (errorString.contains('warning') || 
               errorString.contains('deprecated')) {
      return ErrorSeverity.warning;
    } else {
      return ErrorSeverity.info;
    }
  }
  
  /// Determine network error severity
  ErrorSeverity _determineNetworkErrorSeverity(int? statusCode) {
    if (statusCode == null) return ErrorSeverity.error;
    
    if (statusCode >= 500) return ErrorSeverity.critical;
    if (statusCode >= 400) return ErrorSeverity.error;
    if (statusCode >= 300) return ErrorSeverity.warning;
    return ErrorSeverity.info;
  }
  
  /// Add error log
  void _addErrorLog(ErrorLog errorLog) {
    _errorLogs.add(errorLog);
    
    // Limit memory usage
    if (_errorLogs.length > _maxErrorLogs) {
      _errorLogs.removeAt(0);
    }
    
    // Persist to storage
    _persistErrorLog(errorLog);
  }
  
  /// Persist error log to local storage
  Future<void> _persistErrorLog(ErrorLog errorLog) async {
    try {
      final file = File('${Directory.current.path}/$_errorLogFileName');
      final existingLogs = await _loadPersistedErrors();
      
      existingLogs.add(errorLog);
      
      // Keep only last 1000 errors in storage
      if (existingLogs.length > 1000) {
        existingLogs.removeRange(0, existingLogs.length - 1000);
      }
      
      await file.writeAsString(jsonEncode(existingLogs.map((e) => e.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to persist error log: $e');
      }
    }
  }
  
  /// Load persisted errors from storage
  Future<List<ErrorLog>> _loadPersistedErrors() async {
    try {
      final file = File('${Directory.current.path}/$_errorLogFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((json) => ErrorLog.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load persisted errors: $e');
      }
    }
    return [];
  }
  
  /// Report error to analytics
  void _reportErrorToAnalytics(ErrorLog errorLog) {
    if (errorLog.userId != null) {
      _analytics.trackError(
        userId: errorLog.userId!,
        errorType: errorLog.errorType,
        errorMessage: errorLog.errorMessage,
        stackTrace: errorLog.stackTrace,
        parameters: errorLog.context,
      );
    }
  }
  
  /// Start periodic error reporting timer
  void _startErrorReportingTimer() {
    _errorReportTimer = Timer.periodic(_errorReportInterval, (timer) {
      _reportErrorsToBackend();
    });
  }
  
  /// Report errors to backend
  Future<void> _reportErrorsToBackend() async {
    if (_errorLogs.isEmpty) return;
    
    try {
      // In production, send to error reporting backend (Sentry, Bugsnag, etc.)
      await _sendToBackend(_errorLogs);
      
      // Clear logs after successful send
      _errorLogs.clear();
      
      if (kDebugMode) {
        print('Error logs reported successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to report error logs: $e');
      }
    }
  }
  
  /// Send errors to backend
  Future<void> _sendToBackend(List<ErrorLog> errors) async {
    // Simulate network request
    await Future.delayed(Duration(milliseconds: 100));
    
    // In production, implement actual backend communication
    // Example: Sentry, Bugsnag, Crashlytics, etc.
  }
  
  /// Get error summary
  Map<String, dynamic> getErrorSummary() {
    final now = DateTime.now();
    final last24Hours = now.subtract(Duration(hours: 24));
    
    final recentErrors = _errorLogs.where((error) {
      final errorTime = DateTime.fromMillisecondsSinceEpoch(error.timestamp);
      return errorTime.isAfter(last24Hours);
    }).toList();
    
    final errorTypeCounts = <String, int>{};
    final severityCounts = <ErrorSeverity, int>{};
    final userErrorCounts = <String, int>{};
    
    for (final error in recentErrors) {
      errorTypeCounts[error.errorType] = (errorTypeCounts[error.errorType] ?? 0) + 1;
      severityCounts[error.severity] = (severityCounts[error.severity] ?? 0) + 1;
      if (error.userId != null) {
        userErrorCounts[error.userId!] = (userErrorCounts[error.userId!] ?? 0) + 1;
      }
    }
    
    return {
      'total_errors_24h': recentErrors.length,
      'error_type_counts': errorTypeCounts,
      'severity_counts': severityCounts.map((key, value) => MapEntry(key.name, value)),
      'users_with_errors': userErrorCounts.length,
      'most_affected_users': _getMostAffectedUsers(userErrorCounts),
      'critical_errors': recentErrors.where((e) => e.severity == ErrorSeverity.critical).length,
    };
  }
  
  /// Get most affected users
  List<MapEntry<String, int>> _getMostAffectedUsers(Map<String, int> userErrorCounts) {
    final sortedUsers = userErrorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedUsers.take(10).toList();
  }
  
  /// Get error logs by severity
  List<ErrorLog> getErrorsBySeverity(ErrorSeverity severity) {
    return _errorLogs.where((error) => error.severity == severity).toList();
  }
  
  /// Get error logs by type
  List<ErrorLog> getErrorsByType(String errorType) {
    return _errorLogs.where((error) => error.errorType == errorType).toList();
  }
  
  /// Clear all error logs
  void clearErrorLogs() {
    _errorLogs.clear();
    _clearPersistedErrors();
  }
  
  /// Clear persisted errors
  Future<void> _clearPersistedErrors() async {
    try {
      final file = File('${Directory.current.path}/$_errorLogFileName');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear persisted errors: $e');
      }
    }
  }
  
  /// Dispose error handling service
  void dispose() {
    _errorReportTimer?.cancel();
    _reportErrorsToBackend();
  }
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Error log model
class ErrorLog {
  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final int timestamp;
  final ErrorSeverity severity;
  final Map<String, dynamic> context;
  final String? userId;
  
  ErrorLog({
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    required this.timestamp,
    required this.severity,
    required this.context,
    this.userId,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'timestamp': timestamp,
      'severity': severity.name,
      'context': context,
      'user_id': userId,
    };
  }
  
  /// Create from JSON
  factory ErrorLog.fromJson(Map<String, dynamic> json) {
    return ErrorLog(
      errorType: json['error_type'],
      errorMessage: json['error_message'],
      stackTrace: json['stack_trace'],
      timestamp: json['timestamp'],
      severity: ErrorSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ErrorSeverity.error,
      ),
      context: Map<String, dynamic>.from(json['context']),
      userId: json['user_id'],
    );
  }
  
  @override
  String toString() {
    return 'ErrorLog(errorType: $errorType, errorMessage: $errorMessage, severity: $severity)';
  }
}
