import 'package:ovumate/models/wellness_article.dart';

/// User engagement with articles
class ArticleEngagement {
  final String id;
  final String userId;
  final String articleId;
  final bool isBookmarked;
  final bool isRead;
  final double? rating;
  final String? comment;
  final DateTime? readAt;
  final DateTime? bookmarkedAt;
  final DateTime? ratedAt;
  final DateTime? commentedAt;
  final int readDuration; // in seconds
  final int scrollDepth; // percentage of article read
  final List<String> tags; // user-added tags
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArticleEngagement({
    required this.id,
    required this.userId,
    required this.articleId,
    this.isBookmarked = false,
    this.isRead = false,
    this.rating,
    this.comment,
    this.readAt,
    this.bookmarkedAt,
    this.ratedAt,
    this.commentedAt,
    this.readDuration = 0,
    this.scrollDepth = 0,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create engagement from JSON
  factory ArticleEngagement.fromJson(Map<String, dynamic> json) {
    return ArticleEngagement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      articleId: json['article_id'] as String,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      rating: json['rating'] as double?,
      comment: json['comment'] as String?,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      bookmarkedAt: json['bookmarked_at'] != null ? DateTime.parse(json['bookmarked_at']) : null,
      ratedAt: json['rated_at'] != null ? DateTime.parse(json['rated_at']) : null,
      commentedAt: json['commented_at'] != null ? DateTime.parse(json['commented_at']) : null,
      readDuration: json['read_duration'] as int? ?? 0,
      scrollDepth: json['scroll_depth'] as int? ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'article_id': articleId,
      'is_bookmarked': isBookmarked,
      'is_read': isRead,
      'rating': rating,
      'comment': comment,
      'read_at': readAt?.toIso8601String(),
      'bookmarked_at': bookmarkedAt?.toIso8601String(),
      'rated_at': ratedAt?.toIso8601String(),
      'commented_at': commentedAt?.toIso8601String(),
      'read_duration': readDuration,
      'scroll_depth': scrollDepth,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  ArticleEngagement copyWith({
    String? id,
    String? userId,
    String? articleId,
    bool? isBookmarked,
    bool? isRead,
    double? rating,
    String? comment,
    DateTime? readAt,
    DateTime? bookmarkedAt,
    DateTime? ratedAt,
    DateTime? commentedAt,
    int? readDuration,
    int? scrollDepth,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArticleEngagement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      articleId: articleId ?? this.articleId,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isRead: isRead ?? this.isRead,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      readAt: readAt ?? this.readAt,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      ratedAt: ratedAt ?? this.ratedAt,
      commentedAt: commentedAt ?? this.commentedAt,
      readDuration: readDuration ?? this.readDuration,
      scrollDepth: scrollDepth ?? this.scrollDepth,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Mark article as read
  ArticleEngagement markAsRead({int? readDuration, int? scrollDepth}) {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
      readDuration: readDuration ?? this.readDuration,
      scrollDepth: scrollDepth ?? this.scrollDepth,
      updatedAt: DateTime.now(),
    );
  }

  /// Toggle bookmark
  ArticleEngagement toggleBookmark() {
    return copyWith(
      isBookmarked: !isBookmarked,
      bookmarkedAt: !isBookmarked ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }

  /// Add rating
  ArticleEngagement addRating(double rating) {
    return copyWith(
      rating: rating,
      ratedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Add comment
  ArticleEngagement addComment(String comment) {
    return copyWith(
      comment: comment,
      commentedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Add tag
  ArticleEngagement addTag(String tag) {
    if (tags.contains(tag)) return this;
    final newTags = List<String>.from(tags)..add(tag);
    return copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove tag
  ArticleEngagement removeTag(String tag) {
    if (!tags.contains(tag)) return this;
    final newTags = List<String>.from(tags)..remove(tag);
    return copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if user has engaged with this article
  bool get hasEngagement => isBookmarked || isRead || rating != null || comment != null;

  /// Get engagement score for personalization
  double get engagementScore {
    double score = 0.0;
    
    if (isRead) score += 1.0;
    if (isBookmarked) score += 2.0;
    if (rating != null) score += rating! * 0.5;
    if (comment != null) score += 1.0;
    if (readDuration > 30) score += 0.5; // Read for more than 30 seconds
    if (scrollDepth > 50) score += 0.5; // Read more than 50% of article
    
    return score;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArticleEngagement &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ArticleEngagement{id: $id, userId: $userId, articleId: $articleId, '
           'isBookmarked: $isBookmarked, isRead: $isRead, rating: $rating}';
  }
}

/// User reading preferences and history
class UserReadingProfile {
  final String userId;
  final List<String> favoriteCategories;
  final List<String> favoriteTags;
  final List<String> blockedTags;
  final List<String> favoriteAuthors;
  final int preferredReadingTime; // in minutes
  final ArticleDifficulty preferredDifficulty;
  final bool showBookmarkedOnly;
  final bool showUnreadOnly;
  final DateTime lastActive;
  final Map<String, int> categoryReadCounts;
  final Map<String, double> categoryRatings;

  const UserReadingProfile({
    required this.userId,
    this.favoriteCategories = const [],
    this.favoriteTags = const [],
    this.blockedTags = const [],
    this.favoriteAuthors = const [],
    this.preferredReadingTime = 5,
    this.preferredDifficulty = ArticleDifficulty.beginner,
    this.showBookmarkedOnly = false,
    this.showUnreadOnly = false,
    required this.lastActive,
    this.categoryReadCounts = const {},
    this.categoryRatings = const {},
  });

  /// Create from JSON
  factory UserReadingProfile.fromJson(Map<String, dynamic> json) {
    return UserReadingProfile(
      userId: json['user_id'] as String,
      favoriteCategories: List<String>.from(json['favorite_categories'] ?? []),
      favoriteTags: List<String>.from(json['favorite_tags'] ?? []),
      blockedTags: List<String>.from(json['blocked_tags'] ?? []),
      favoriteAuthors: List<String>.from(json['favorite_authors'] ?? []),
      preferredReadingTime: json['preferred_reading_time'] as int? ?? 5,
      preferredDifficulty: ArticleDifficulty.values.firstWhere(
        (e) => e.toString() == json['preferred_difficulty'],
        orElse: () => ArticleDifficulty.beginner,
      ),
      showBookmarkedOnly: json['show_bookmarked_only'] as bool? ?? false,
      showUnreadOnly: json['show_unread_only'] as bool? ?? false,
      lastActive: DateTime.parse(json['last_active']),
      categoryReadCounts: Map<String, int>.from(json['category_read_counts'] ?? {}),
      categoryRatings: Map<String, double>.from(json['category_ratings'] ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'favorite_categories': favoriteCategories,
      'favorite_tags': favoriteTags,
      'blocked_tags': blockedTags,
      'favorite_authors': favoriteAuthors,
      'preferred_reading_time': preferredReadingTime,
      'preferred_difficulty': preferredDifficulty.toString(),
      'show_bookmarked_only': showBookmarkedOnly,
      'show_unread_only': showUnreadOnly,
      'last_active': lastActive.toIso8601String(),
      'category_read_counts': categoryReadCounts,
      'category_ratings': categoryRatings,
    };
  }

  /// Update last active time
  UserReadingProfile updateLastActive() {
    return copyWith(lastActive: DateTime.now());
  }

  /// Add favorite category
  UserReadingProfile addFavoriteCategory(String category) {
    if (favoriteCategories.contains(category)) return this;
    final newCategories = List<String>.from(favoriteCategories)..add(category);
    return copyWith(favoriteCategories: newCategories);
  }

  /// Remove favorite category
  UserReadingProfile removeFavoriteCategory(String category) {
    if (!favoriteCategories.contains(category)) return this;
    final newCategories = List<String>.from(favoriteCategories)..remove(category);
    return copyWith(favoriteCategories: newCategories);
  }

  /// Update category read count
  UserReadingProfile updateCategoryReadCount(String category) {
    final newCounts = Map<String, int>.from(categoryReadCounts);
    newCounts[category] = (newCounts[category] ?? 0) + 1;
    return copyWith(categoryReadCounts: newCounts);
  }

  /// Update category rating
  UserReadingProfile updateCategoryRating(String category, double rating) {
    final newRatings = Map<String, double>.from(categoryRatings);
    final currentRating = newRatings[category] ?? 0.0;
    final currentCount = categoryReadCounts[category] ?? 0;
    
    // Calculate weighted average
    final newRating = ((currentRating * currentCount) + rating) / (currentCount + 1);
    newRatings[category] = newRating;
    
    return copyWith(categoryRatings: newRatings);
  }

  /// Create a copy with updated values
  UserReadingProfile copyWith({
    String? userId,
    List<String>? favoriteCategories,
    List<String>? favoriteTags,
    List<String>? blockedTags,
    List<String>? favoriteAuthors,
    int? preferredReadingTime,
    ArticleDifficulty? preferredDifficulty,
    bool? showBookmarkedOnly,
    bool? showUnreadOnly,
    DateTime? lastActive,
    Map<String, int>? categoryReadCounts,
    Map<String, double>? categoryRatings,
  }) {
    return UserReadingProfile(
      userId: userId ?? this.userId,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      favoriteTags: favoriteTags ?? this.favoriteTags,
      blockedTags: blockedTags ?? this.blockedTags,
      favoriteAuthors: favoriteAuthors ?? this.favoriteAuthors,
      preferredReadingTime: preferredReadingTime ?? this.preferredReadingTime,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      showBookmarkedOnly: showBookmarkedOnly ?? this.showBookmarkedOnly,
      showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
      lastActive: lastActive ?? this.lastActive,
      categoryReadCounts: categoryReadCounts ?? this.categoryReadCounts,
      categoryRatings: categoryRatings ?? this.categoryRatings,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserReadingProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'UserReadingProfile{userId: $userId, favoriteCategories: $favoriteCategories, '
           'preferredReadingTime: $preferredReadingTime}';
  }
}
