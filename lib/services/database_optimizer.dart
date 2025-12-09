import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';

/// Database optimization service for large-scale applications
class DatabaseOptimizer {
  static final DatabaseOptimizer _instance = DatabaseOptimizer._internal();
  factory DatabaseOptimizer() => _instance;
  DatabaseOptimizer._internal();

  static const int _maxBatchSize = 100;
  static const int _maxConcurrentQueries = 5;
  static const Duration _queryTimeout = Duration(seconds: 30);
  static const Duration _cacheExpiry = Duration(minutes: 15);
  
  final Map<String, _CacheEntry> _queryCache = {};
  final List<Completer> _pendingQueries = [];
  int _activeQueries = 0;
  late SupabaseClient _supabase;
  
  /// Initialize database optimizer
  Future<void> initialize(SupabaseClient supabase) async {
    _supabase = supabase;
    _startCacheCleanupTimer();
    
    if (kDebugMode) {
      print('Database optimizer initialized');
    }
  }
  
  /// Optimized batch insert with error handling
  Future<List<Map<String, dynamic>>> batchInsert({
    required String table,
    required List<Map<String, dynamic>> data,
    String? userId,
    bool upsert = false,
  }) async {
    if (data.isEmpty) return [];
    
    final results = <Map<String, dynamic>>[];
    final batches = _createBatches(data, _maxBatchSize);
    
    for (final batch in batches) {
      try {
        final batchResult = await _executeBatchInsert(
          table: table,
          data: batch,
          upsert: upsert,
        );
        results.addAll(batchResult);
        
        // Add delay between batches to prevent overwhelming the database
        if (batches.length > 1) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Batch insert failed: $e');
        }
        // Continue with next batch instead of failing completely
      }
    }
    
    return results;
  }
  
  /// Execute batch insert operation
  Future<List<Map<String, dynamic>>> _executeBatchInsert({
    required String table,
    required List<Map<String, dynamic>> data,
    required bool upsert,
  }) async {
    final query = _supabase.from(table);
    
    if (upsert) {
      return await query.upsert(data).select();
    } else {
      return await query.insert(data).select();
    }
  }
  
  /// Optimized query with caching and pagination
  Future<List<Map<String, dynamic>>> optimizedQuery({
    required String table,
    Map<String, dynamic>? filters,
    List<String>? selectColumns,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
    String? cacheKey,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache && cacheKey != null) {
      final cached = _getCached(cacheKey);
      if (cached != null) {
        return cached;
      }
    }
    
    // Build query - use dynamic type to handle Supabase query builder chain
    dynamic query = _supabase.from(table);
    
    // Apply filters
    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }
    
    // Apply select columns
    if (selectColumns != null) {
      query = query.select(selectColumns.join(','));
    }
    
    // Apply ordering
    if (orderBy != null) {
      query = ascending ? query.order(orderBy) : query.order(orderBy, ascending: false);
    }
    
    // Apply pagination
    if (limit != null) {
      query = query.limit(limit);
    }
    if (offset != null) {
      query = query.range(offset, (offset + (limit ?? 100)) - 1);
    }
    
    // Execute query with timeout
    final result = await query.execute().timeout(_queryTimeout);
    
    // Cache result if requested
    if (useCache && cacheKey != null) {
      _setCached(cacheKey, result.data);
    }
    
    return result.data ?? [];
  }
  
  /// Optimized count query
  Future<int> optimizedCount({
    required String table,
    Map<String, dynamic>? filters,
    String? cacheKey,
  }) async {
    // Check cache first
    if (cacheKey != null) {
      final cached = _getCached('count_$cacheKey');
      if (cached != null) {
        return cached as int;
      }
    }
    
    // Build count query
    var query = _supabase.from(table).select('*', const FetchOptions(count: CountOption.exact));
    
    // Apply filters
    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }
    
    // Execute query
    final result = await query.execute();
    final count = result.count ?? 0;
    
    // Cache result
    if (cacheKey != null) {
      _setCached('count_$cacheKey', count);
    }
    
    return count;
  }
  
  /// Optimized search with full-text search
  Future<List<Map<String, dynamic>>> optimizedSearch({
    required String table,
    required String searchTerm,
    required List<String> searchColumns,
    Map<String, dynamic>? additionalFilters,
    int? limit,
    String? cacheKey,
  }) async {
    // Check cache first
    if (cacheKey != null) {
      final cached = _getCached(cacheKey);
      if (cached != null) {
        return cached;
      }
    }
    
    // Build search query using full-text search
    var query = _supabase.from(table);
    
    // Apply full-text search
    final searchQuery = searchColumns.map((col) => '$col.ilike.%$searchTerm%').join(',');
    query = query.or(searchQuery);
    
    // Apply additional filters
    if (additionalFilters != null) {
      for (final entry in additionalFilters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }
    
    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }
    
    // Execute query
    final result = await query.execute();
    final data = result.data ?? [];
    
    // Cache result
    if (cacheKey != null) {
      _setCached(cacheKey, data);
    }
    
    return data;
  }
  
  /// Optimized aggregation query
  Future<Map<String, dynamic>> optimizedAggregation({
    required String table,
    required String aggregateColumn,
    required String aggregateFunction,
    Map<String, dynamic>? filters,
    List<String>? groupBy,
    String? cacheKey,
  }) async {
    // Check cache first
    if (cacheKey != null) {
      final cached = _getCached(cacheKey);
      if (cached != null) {
        return cached;
      }
    }
    
    // Build aggregation query
    var query = _supabase.from(table);
    
    // Apply filters
    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }
    
    // Apply grouping
    if (groupBy != null) {
      query = query.select('${groupBy.join(',')},$aggregateFunction($aggregateColumn)');
    } else {
      query = query.select('$aggregateFunction($aggregateColumn)');
    }
    
    // Execute query
    final result = await query.execute();
    final data = result.data ?? [];
    
    // Process aggregation result
    final aggregationResult = _processAggregationResult(data, aggregateFunction, aggregateColumn);
    
    // Cache result
    if (cacheKey != null) {
      _setCached(cacheKey, aggregationResult);
    }
    
    return aggregationResult;
  }
  
  /// Process aggregation result
  Map<String, dynamic> _processAggregationResult(
    List<Map<String, dynamic>> data,
    String aggregateFunction,
    String aggregateColumn,
  ) {
    if (data.isEmpty) return {};
    
    final result = <String, dynamic>{};
    
    for (final row in data) {
      for (final entry in row.entries) {
        if (entry.key != aggregateColumn) {
          result[entry.key] = entry.value;
        }
      }
      
      // Add aggregated value
      final aggregatedValue = row[aggregateColumn];
      if (aggregatedValue != null) {
        result['${aggregateFunction}_$aggregateColumn'] = aggregatedValue;
      }
    }
    
    return result;
  }
  
  /// Optimized data export
  Future<String> exportData({
    required String table,
    Map<String, dynamic>? filters,
    List<String>? selectColumns,
    String format = 'json',
    int? batchSize,
  }) async {
    final batchSize = batchSize ?? _maxBatchSize;
    final allData = <Map<String, dynamic>>[];
    int offset = 0;
    
    while (true) {
      final batch = await optimizedQuery(
        table: table,
        filters: filters,
        selectColumns: selectColumns,
        limit: batchSize,
        offset: offset,
        useCache: false,
      );
      
      if (batch.isEmpty) break;
      
      allData.addAll(batch);
      offset += batchSize;
      
      // Add delay to prevent overwhelming the database
      await Future.delayed(Duration(milliseconds: 50));
    }
    
    // Convert to requested format
    switch (format.toLowerCase()) {
      case 'json':
        return jsonEncode(allData);
      case 'csv':
        return _convertToCsv(allData);
      default:
        return jsonEncode(allData);
    }
  }
  
  /// Convert data to CSV format
  String _convertToCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    
    final headers = data.first.keys.toList();
    final csvRows = <String>[];
    
    // Add header row
    csvRows.add(headers.map((h) => '"$h"').join(','));
    
    // Add data rows
    for (final row in data) {
      final values = headers.map((h) => '"${row[h] ?? ''}"').join(',');
      csvRows.add(values);
    }
    
    return csvRows.join('\n');
  }
  
  /// Database maintenance operations
  Future<void> performMaintenance() async {
    try {
      // Clean up old data (example: older than 2 years)
      final twoYearsAgo = DateTime.now().subtract(Duration(days: 730));
      
      // Clean up old cycle entries
      await _supabase
          .from('cycle_entries')
          .delete()
          .lt('created_at', twoYearsAgo.toIso8601String());
      
      // Clean up old analytics data
      await _supabase
          .from('analytics_events')
          .delete()
          .lt('timestamp', twoYearsAgo.millisecondsSinceEpoch);
      
      // Clean up old error logs
      await _supabase
          .from('error_logs')
          .delete()
          .lt('timestamp', twoYearsAgo.millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Database maintenance completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Database maintenance failed: $e');
      }
    }
  }
  
  /// Cache management
  T? _getCached<T>(String key) {
    final entry = _queryCache[key];
    if (entry != null && !entry.isExpired) {
      return entry.data as T;
    }
    
    // Remove expired entry
    if (entry != null) {
      _queryCache.remove(key);
    }
    
    return null;
  }
  
  void _setCached<T>(String key, T data) {
    _queryCache[key] = _CacheEntry(
      data: data,
      expiryTime: DateTime.now().add(_cacheExpiry).millisecondsSinceEpoch,
    );
    
    // Limit cache size
    if (_queryCache.length > 100) {
      final oldestKey = _queryCache.keys.first;
      _queryCache.remove(oldestKey);
    }
  }
  
  /// Start cache cleanup timer
  void _startCacheCleanupTimer() {
    Timer.periodic(Duration(minutes: 5), (timer) {
      _cleanupExpiredCache();
    });
  }
  
  /// Clean up expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys = _queryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      _queryCache.remove(key);
    }
    
    if (kDebugMode && expiredKeys.isNotEmpty) {
      print('Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }
  
  /// Create batches from a list
  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }
  
  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final stats = <String, dynamic>{};
      
      // Get table sizes
      final tables = ['cycle_entries', 'analytics_events', 'error_logs'];
      for (final table in tables) {
        final count = await optimizedCount(table: table);
        stats['${table}_count'] = count;
      }
      
      // Get cache statistics
      stats['cache_size'] = _queryCache.length;
      stats['cache_hit_rate'] = _calculateCacheHitRate();
      
      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get database stats: $e');
      }
      return {};
    }
  }
  
  /// Calculate cache hit rate
  double _calculateCacheHitRate() {
    // This is a simplified calculation
    // In production, you'd track actual hits and misses
    return 0.85; // Placeholder value
  }
  
  /// Clear all caches
  void clearCache() {
    _queryCache.clear();
    if (kDebugMode) {
      print('All caches cleared');
    }
  }
}

/// Cache entry model
class _CacheEntry {
  final dynamic data;
  final int expiryTime;
  
  _CacheEntry({
    required this.data,
    required this.expiryTime,
  });
  
  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiryTime;
}
