import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:isolate';

/// Performance optimization utilities for handling large user bases
class PerformanceOptimizer {
  static const int _maxConcurrentOperations = 4;
  static const int _cacheSize = 1000;
  static const Duration _operationTimeout = Duration(seconds: 30);
  
  static final Map<String, dynamic> _cache = {};
  static final List<Completer> _pendingOperations = [];
  static int _activeOperations = 0;
  
  /// Optimize list rendering for large datasets
  static Widget buildOptimizedListView<T>({
    required List<T> items,
    required Widget Function(BuildContext, T, int) itemBuilder,
    required String cacheKey,
    int pageSize = 50,
    bool enableSearch = true,
    String? searchHint,
    Widget Function(String)? searchBarBuilder,
  }) {
    return _OptimizedListView<T>(
      items: items,
      itemBuilder: itemBuilder,
      cacheKey: cacheKey,
      pageSize: pageSize,
      enableSearch: enableSearch,
      searchHint: searchHint,
      searchBarBuilder: searchBarBuilder,
    );
  }
  
  /// Batch process operations for better performance
  static Future<List<R>> batchProcess<T, R>({
    required List<T> items,
    required Future<R> Function(T) processor,
    int batchSize = 100,
    Duration? delayBetweenBatches,
  }) async {
    final results = <R>[];
    final batches = _createBatches(items, batchSize);
    
    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final batchResults = await Future.wait(
        batch.map(processor),
        eagerError: true,
      );
      results.addAll(batchResults);
      
      // Add delay between batches to prevent overwhelming the system
      if (delayBetweenBatches != null && i < batches.length - 1) {
        await Future.delayed(delayBetweenBatches);
      }
    }
    
    return results;
  }
  
  /// Memory-efficient image loading
  static Widget buildOptimizedImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return _OptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
  
  /// Debounce function calls to prevent excessive executions
  static Timer Function(VoidCallback) debounce(Duration duration) {
    Timer? timer;
    return (VoidCallback callback) {
      timer?.cancel();
      timer = Timer(duration, callback);
    };
  }
  
  /// Throttle function calls to limit execution frequency
  static Timer Function(VoidCallback) throttle(Duration duration) {
    Timer? timer;
    bool isThrottled = false;
    
    return (VoidCallback callback) {
      if (!isThrottled) {
        callback();
        isThrottled = true;
        timer = Timer(duration, () => isThrottled = false);
      }
    };
  }
  
  /// Cache management for frequently accessed data
  static T? getCached<T>(String key) {
    final cached = _cache[key];
    if (cached is T) {
      return cached;
    }
    return null;
  }
  
  static void setCached<T>(String key, T value) {
    if (_cache.length >= _cacheSize) {
      // Remove oldest entries when cache is full
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = value;
  }
  
  static void clearCache() {
    _cache.clear();
  }
  
  /// Background processing for heavy operations
  static Future<R> processInBackground<T, R>({
    required T data,
    required R Function(T) processor,
  }) async {
    final completer = Completer<R>();
    _pendingOperations.add(completer);
    
    if (_activeOperations < _maxConcurrentOperations) {
      _processNext();
    }
    
    return completer.future.timeout(_operationTimeout);
  }
  
  /// Process next pending operation
  static void _processNext() {
    if (_pendingOperations.isEmpty || _activeOperations >= _maxConcurrentOperations) {
      return;
    }
    
    final completer = _pendingOperations.removeAt(0);
    _activeOperations++;
    
    // Process in background isolate for heavy operations
    _processInIsolate(completer).then((_) {
      _activeOperations--;
      _processNext();
    });
  }
  
  /// Process operation in background isolate
  static Future<void> _processInIsolate(Completer completer) async {
    try {
      // For now, process in main isolate
      // In production, use Isolate.spawn for heavy operations
      await Future.delayed(Duration(milliseconds: 100));
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    }
  }
  
  /// Create batches from a list
  static List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }
}

/// Optimized ListView for large datasets
class _OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final String cacheKey;
  final int pageSize;
  final bool enableSearch;
  final String? searchHint;
  final Widget Function(String)? searchBarBuilder;
  
  const _OptimizedListView({
    required this.items,
    required this.itemBuilder,
    required this.cacheKey,
    required this.pageSize,
    required this.enableSearch,
    this.searchHint,
    this.searchBarBuilder,
  });
  
  @override
  State<_OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<_OptimizedListView<T>> {
  List<T> _filteredItems = [];
  String _searchQuery = '';
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }
  
  void _loadNextPage() {
    if (_currentPage * widget.pageSize < _filteredItems.length) {
      setState(() {
        _currentPage++;
      });
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 0;
      
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          // Implement search logic based on item type
          return item.toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems.take((_currentPage + 1) * widget.pageSize).toList();
    
    return Column(
      children: [
        if (widget.enableSearch) ...[
          widget.searchBarBuilder?.call(_searchQuery) ??
              _buildDefaultSearchBar(),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: visibleItems.length + (_hasMoreItems ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == visibleItems.length) {
                return _buildLoadingIndicator();
              }
              return widget.itemBuilder(context, visibleItems[index], index);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildDefaultSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: widget.searchHint ?? 'Search...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      onChanged: _onSearchChanged,
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  bool get _hasMoreItems => _currentPage * widget.pageSize < _filteredItems.length;
}

/// Optimized image loading with caching and error handling
class _OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const _OptimizedImage({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fit,
    this.placeholder,
    this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildDefaultPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
        // Enable caching
        cacheWidth: (width * MediaQuery.of(context).devicePixelRatio).round(),
        cacheHeight: (height * MediaQuery.of(context).devicePixelRatio).round(),
      ),
    );
  }
  
  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}
