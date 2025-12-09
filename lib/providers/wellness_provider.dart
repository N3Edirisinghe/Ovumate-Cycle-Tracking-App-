import 'package:flutter/material.dart';
import 'package:ovumate/models/wellness_article.dart';
import 'package:ovumate/models/user_profile.dart';
import 'package:ovumate/services/article_service.dart';

class WellnessProvider extends ChangeNotifier {
  List<WellnessArticle> _articles = [];
  List<WellnessArticle> _featuredArticles = [];
  List<WellnessArticle> _filteredArticles = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Filtering and search
  ArticleCategory? _selectedCategory;
  ArticleDifficulty? _selectedDifficulty;
  String _searchQuery = '';
  bool _showPremiumOnly = false;

  // Getters
  List<WellnessArticle> get articles => _articles;
  List<WellnessArticle> get featuredArticles => _featuredArticles;
  List<WellnessArticle> get filteredArticles => _filteredArticles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ArticleCategory? get selectedCategory => _selectedCategory;
  ArticleDifficulty? get selectedDifficulty => _selectedDifficulty;
  String get searchQuery => _searchQuery;
  bool get showPremiumOnly => _showPremiumOnly;
  bool get isInitialized => true; // Always initialized for local storage

  // Initialize wellness data
  Future<void> initialize() async {
    try {
      _setLoading(true);
      
      // Load articles from ArticleService (internet-based)
      await _loadArticles();
      _filterArticles();
    } catch (e) {
      debugPrint('Wellness provider initialization error: $e');
      _setError('Failed to initialize wellness data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load articles from internet service
  Future<void> _loadArticles() async {
    try {
      debugPrint('🔵 Starting to load articles...');
      // Clear cache to ensure articles load in current language
      await ArticleService.clearCache();
      debugPrint('🔵 Cache cleared');
      
      // Load articles from internet service
      debugPrint('🔵 Calling ArticleService.initializeArticles()...');
      _articles = await ArticleService.initializeArticles();
      debugPrint('🔵 Got ${_articles.length} articles');
      
      debugPrint('🔵 Filtering featured articles...');
      _featuredArticles = _articles
          .where((article) => article.isFeatured)
          .toList();
      debugPrint('🔵 Got ${_featuredArticles.length} featured articles');
    } catch (e, stackTrace) {
      debugPrint('🔴 Error loading articles: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      // Set default articles or handle gracefully
      _articles = [];
      _featuredArticles = [];
    }
  }

  // Filter articles based on current filters
  void _filterArticles() {
    _filteredArticles = _articles.where((article) {
      // Category filter
      if (_selectedCategory != null && article.category != _selectedCategory) {
        return false;
      }
      
      // Difficulty filter
      if (_selectedDifficulty != null && article.difficulty != _selectedDifficulty) {
        return false;
      }
      
      // Premium filter
      if (_showPremiumOnly && !article.isPremium) {
        return false;
      }
      
      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = article.title.toLowerCase().contains(query);
        final matchesSummary = article.summary.toLowerCase().contains(query);
        final matchesTags = article.tags.any((tag) => tag.toLowerCase().contains(query));
        
        if (!matchesTitle && !matchesSummary && !matchesTags) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    notifyListeners();
  }

  // Set category filter
  void setCategoryFilter(ArticleCategory? category) {
    _selectedCategory = category;
    _filterArticles();
  }

  // Set difficulty filter
  void setDifficultyFilter(ArticleDifficulty? difficulty) {
    _selectedDifficulty = difficulty;
    _filterArticles();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterArticles();
  }

  // Toggle premium filter
  void togglePremiumFilter() {
    _showPremiumOnly = !_showPremiumOnly;
    _filterArticles();
  }

  // Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedDifficulty = null;
    _searchQuery = '';
    _showPremiumOnly = false;
    _filterArticles();
  }

  // Get articles by category
  List<WellnessArticle> getArticlesByCategory(ArticleCategory category) {
    return _articles
        .where((article) => article.category == category)
        .toList();
  }

  // Get articles by difficulty
  List<WellnessArticle> getArticlesByDifficulty(ArticleDifficulty difficulty) {
    return _articles
        .where((article) => article.difficulty == difficulty)
        .toList();
  }

  // Get related articles
  List<WellnessArticle> getRelatedArticles(String articleId, {int limit = 3}) {
    final article = _articles.firstWhere((a) => a.id == articleId);
    if (article.relatedArticles.isEmpty) {
      // If no related articles specified, return articles from same category
      return _articles
          .where((a) => a.id != articleId && a.category == article.category)
          .take(limit)
          .toList();
    }
    
    return _articles
        .where((a) => article.relatedArticles.contains(a.id))
        .take(limit)
        .toList();
  }

  // Get trending articles (based on view count and rating)
  List<WellnessArticle> getTrendingArticles({int limit = 5}) {
    final sortedArticles = List<WellnessArticle>.from(_articles);
    sortedArticles.sort((a, b) {
      // Sort by rating first, then by view count
      if (a.rating != b.rating) {
        return b.rating.compareTo(a.rating);
      }
      return b.viewCount.compareTo(a.viewCount);
    });
    
    return sortedArticles.take(limit).toList();
  }

  // Get new articles (published in last 30 days)
  List<WellnessArticle> getNewArticles({int limit = 5}) {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    
    return _articles
        .where((article) => article.publishedAt.isAfter(thirtyDaysAgo))
        .take(limit)
        .toList();
  }

  // Increment article view count (local only)
  Future<void> incrementViewCount(String articleId) async {
    try {
      final article = _articles.firstWhere((a) => a.id == articleId);
      final updatedArticle = article.copyWith(
        viewCount: article.viewCount + 1,
      );
      
      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = updatedArticle;
        _filterArticles();
      }
    } catch (e) {
      // Silently fail for view count updates
      debugPrint('Failed to increment view count: $e');
    }
  }

  // Rate article (local only)
  Future<bool> rateArticle(String articleId, double rating) async {
    try {
      final article = _articles.firstWhere((a) => a.id == articleId);
      final newRatingCount = article.ratingCount + 1;
      final newRating = ((article.rating * article.ratingCount) + rating) / newRatingCount;
      
      final updatedArticle = article.copyWith(
        rating: newRating,
        ratingCount: newRatingCount,
      );
      
      final index = _articles.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        _articles[index] = updatedArticle;
        _filterArticles();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Failed to rate article: $e');
      return false;
    }
  }

  // Get personalized article recommendations
  List<WellnessArticle> getPersonalizedRecommendations(UserProfile userProfile, {int limit = 10}) {
    final userProfileMap = {
      'age': userProfile.age,
      'interests': userProfile.wellnessGoals,
      'health_conditions': userProfile.healthConditions,
      'cycle_length': userProfile.averageCycleLength ?? 28,
      'last_period': userProfile.lastPeriodStart,
    };
    
    return ArticleService.getPersonalizedRecommendations(
      _articles, 
      userProfileMap, 
      limit: limit,
    );
  }
  

  
  // Enhanced search with smart matching
  List<WellnessArticle> searchArticlesAdvanced(String query, {int limit = 50}) {
    if (query.isEmpty) return _filteredArticles.take(limit).toList();
    
    final searchResults = ArticleService.searchArticles(_articles, query, limit: limit);
    
    // Apply current filters to search results
    return searchResults.where((article) {
      // Category filter
      if (_selectedCategory != null && article.category != _selectedCategory) {
        return false;
      }
      
      // Difficulty filter
      if (_selectedDifficulty != null && article.difficulty != _selectedDifficulty) {
        return false;
      }
      
      // Premium filter
      if (_showPremiumOnly && !article.isPremium) {
        return false;
      }
      
      return true;
    }).toList();
  }

  // Refresh articles manually
  Future<void> refreshArticles() async {
    try {
      _setLoading(true);
      _errorMessage = null;
      
      debugPrint('🔵 Refreshing articles...');
      // Clear cache first to force reload with current language
      await ArticleService.clearCache();
      debugPrint('🔵 Cache cleared for refresh');
      
      // Force refresh from internet
      debugPrint('🔵 Calling ArticleService.refreshArticles()...');
      _articles = await ArticleService.refreshArticles();
      debugPrint('🔵 Refreshed ${_articles.length} articles');
      
      _featuredArticles = _articles
          .where((article) => article.isFeatured)
          .toList();
      debugPrint('🔵 Filtered ${_featuredArticles.length} featured articles');
          
      _filterArticles();
      debugPrint('🔵 Articles refresh complete');
    } catch (e, stackTrace) {
      debugPrint('🔴 Error refreshing articles: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      _setError('Failed to refresh articles: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check if articles should be updated
  Future<bool> shouldUpdateArticles() async {
    return await ArticleService.shouldUpdateArticles();
  }

  // Get last update time
  String getLastUpdateTime() {
    // This would typically come from ArticleService
    return 'Updated today';
  }

  // Clear all articles (useful when changing language)
  void clearAllArticles() {
    _articles = [];
    _featuredArticles = [];
    _filteredArticles = [];
    _errorMessage = null;
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }



  // Get available categories
  List<ArticleCategory> get availableCategories {
    return ArticleCategory.values;
  }

  // Get available difficulties
  List<ArticleDifficulty> get availableDifficulties {
    return ArticleDifficulty.values;
  }

  // Get filter summary
  String get filterSummary {
    final filters = <String>[];
    
    if (_selectedCategory != null) {
      filters.add(_selectedCategory!.categoryDisplayName);
    }
    
    if (_selectedDifficulty != null) {
      filters.add(_selectedDifficulty!.difficultyDisplayName);
    }
    
    if (_searchQuery.isNotEmpty) {
      filters.add('"$_searchQuery"');
    }
    
    if (_showPremiumOnly) {
      filters.add('Premium only');
    }
    
    if (filters.isEmpty) {
      return 'All articles';
    }
    
    return filters.join(' • ');
  }
}

