import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Analytics service for tracking user behavior and app performance
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static const String _analyticsFileName = 'analytics_data.json';
  static const int _maxEventsInMemory = 1000;
  static const Duration _flushInterval = Duration(minutes: 5);
  
  final List<AnalyticsEvent> _events = [];
  Timer? _flushTimer;
  bool _isInitialized = false;
  
  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _startFlushTimer();
    await _loadPersistedEvents();
    _isInitialized = true;
    
    if (kDebugMode) {
      print('Analytics service initialized');
    }
  }
  
  /// Track user action
  void trackEvent({
    required String eventName,
    required String userId,
    Map<String, dynamic>? parameters,
    String? category,
    String? action,
    String? label,
    int? value,
  }) {
    final event = AnalyticsEvent(
      eventName: eventName,
      userId: userId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      parameters: parameters ?? {},
      category: category,
      action: action,
      label: label,
      value: value,
    );
    
    _addEvent(event);
  }
  
  /// Track screen view
  void trackScreenView({
    required String screenName,
    required String userId,
    Map<String, dynamic>? parameters,
  }) {
    trackEvent(
      eventName: 'screen_view',
      userId: userId,
      parameters: {
        'screen_name': screenName,
        ...?parameters,
      },
      category: 'navigation',
      action: 'view',
      label: screenName,
    );
  }
  
  /// Track user engagement
  void trackEngagement({
    required String userId,
    required String feature,
    required String action,
    Map<String, dynamic>? parameters,
  }) {
    trackEvent(
      eventName: 'user_engagement',
      userId: userId,
      parameters: {
        'feature': feature,
        'action': action,
        ...?parameters,
      },
      category: 'engagement',
      action: action,
      label: feature,
    );
  }
  
  /// Track performance metrics
  void trackPerformance({
    required String userId,
    required String metric,
    required double value,
    String? unit,
    Map<String, dynamic>? parameters,
  }) {
    trackEvent(
      eventName: 'performance_metric',
      userId: userId,
      parameters: {
        'metric': metric,
        'value': value,
        'unit': unit,
        ...?parameters,
      },
      category: 'performance',
      action: 'measure',
      label: metric,
      value: value.round(),
    );
  }
  
  /// Track error events
  void trackError({
    required String userId,
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    Map<String, dynamic>? parameters,
  }) {
    trackEvent(
      eventName: 'error_occurred',
      userId: userId,
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        ...?parameters,
      },
      category: 'error',
      action: 'occurred',
      label: errorType,
    );
  }
  
  /// Track feature usage
  void trackFeatureUsage({
    required String userId,
    required String feature,
    required String action,
    Map<String, dynamic>? parameters,
  }) {
    trackEvent(
      eventName: 'feature_usage',
      userId: userId,
      parameters: {
        'feature': feature,
        'action': action,
        ...?parameters,
      },
      category: 'feature',
      action: action,
      label: feature,
    );
  }
  
  /// Track user journey
  void trackUserJourney({
    required String userId,
    required String step,
    required String journey,
    Map<String, dynamic>? parameters,
  }) {
    trackEvent(
      eventName: 'user_journey',
      userId: userId,
      parameters: {
        'step': step,
        'journey': journey,
        ...?parameters,
      },
      category: 'journey',
      action: 'step',
      label: journey,
    );
  }
  
  /// Add event to memory
  void _addEvent(AnalyticsEvent event) {
    _events.add(event);
    
    // Limit memory usage
    if (_events.length > _maxEventsInMemory) {
      _events.removeAt(0);
    }
    
    // Persist to storage
    _persistEvent(event);
  }
  
  /// Persist event to local storage
  Future<void> _persistEvent(AnalyticsEvent event) async {
    try {
      final file = File('${Directory.current.path}/$_analyticsFileName');
      final existingData = await _loadPersistedEvents();
      
      existingData.add(event);
      
      // Keep only last 1000 events in storage
      if (existingData.length > 1000) {
        existingData.removeRange(0, existingData.length - 1000);
      }
      
      await file.writeAsString(jsonEncode(existingData.map((e) => e.toJson()).toList()));
    } catch (e) {
      if (kDebugMode) {
        print('Failed to persist analytics event: $e');
      }
    }
  }
  
  /// Load persisted events from storage
  Future<List<AnalyticsEvent>> _loadPersistedEvents() async {
    try {
      final file = File('${Directory.current.path}/$_analyticsFileName');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        return jsonList.map((json) => AnalyticsEvent.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load persisted events: $e');
      }
    }
    return [];
  }
  
  /// Start periodic flush timer
  void _startFlushTimer() {
    _flushTimer = Timer.periodic(_flushInterval, (timer) {
      _flushEvents();
    });
  }
  
  /// Flush events to analytics backend
  Future<void> _flushEvents() async {
    if (_events.isEmpty) return;
    
    try {
      // In production, send to analytics backend (Firebase, Mixpanel, etc.)
      await _sendToBackend(_events);
      
      // Clear events after successful send
      _events.clear();
      
      if (kDebugMode) {
        print('Analytics events flushed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to flush analytics events: $e');
      }
    }
  }
  
  /// Send events to analytics backend
  Future<void> _sendToBackend(List<AnalyticsEvent> events) async {
    // Simulate network request
    await Future.delayed(Duration(milliseconds: 100));
    
    // In production, implement actual backend communication
    // Example: Firebase Analytics, Mixpanel, Amplitude, etc.
  }
  
  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final now = DateTime.now();
    final last24Hours = now.subtract(Duration(hours: 24));
    
    final recentEvents = _events.where((event) {
      final eventTime = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
      return eventTime.isAfter(last24Hours);
    }).toList();
    
    final eventCounts = <String, int>{};
    final userCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    
    for (final event in recentEvents) {
      eventCounts[event.eventName] = (eventCounts[event.eventName] ?? 0) + 1;
      userCounts[event.userId] = (userCounts[event.userId] ?? 0) + 1;
      if (event.category != null) {
        categoryCounts[event.category!] = (categoryCounts[event.category!] ?? 0) + 1;
      }
    }
    
    return {
      'total_events_24h': recentEvents.length,
      'unique_users_24h': userCounts.length,
      'event_counts': eventCounts,
      'category_counts': categoryCounts,
      'most_active_users': _getMostActiveUsers(userCounts),
      'top_events': _getTopEvents(eventCounts),
    };
  }
  
  /// Get most active users
  List<MapEntry<String, int>> _getMostActiveUsers(Map<String, int> userCounts) {
    final sortedUsers = userCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedUsers.take(10).toList();
  }
  
  /// Get top events
  List<MapEntry<String, int>> _getTopEvents(Map<String, int> eventCounts) {
    final sortedEvents = eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEvents.take(10).toList();
  }
  
  /// Dispose analytics service
  void dispose() {
    _flushTimer?.cancel();
    _flushEvents();
  }
}

/// Analytics event model
class AnalyticsEvent {
  final String eventName;
  final String userId;
  final int timestamp;
  final Map<String, dynamic> parameters;
  final String? category;
  final String? action;
  final String? label;
  final int? value;
  
  AnalyticsEvent({
    required this.eventName,
    required this.userId,
    required this.timestamp,
    required this.parameters,
    this.category,
    this.action,
    this.label,
    this.value,
  });
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'event_name': eventName,
      'user_id': userId,
      'timestamp': timestamp,
      'parameters': parameters,
      'category': category,
      'action': action,
      'label': label,
      'value': value,
    };
  }
  
  /// Create from JSON
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventName: json['event_name'],
      userId: json['user_id'],
      timestamp: json['timestamp'],
      parameters: Map<String, dynamic>.from(json['parameters']),
      category: json['category'],
      action: json['action'],
      label: json['label'],
      value: json['value'],
    );
  }
  
  @override
  String toString() {
    return 'AnalyticsEvent(eventName: $eventName, userId: $userId, timestamp: $timestamp)';
  }
}
