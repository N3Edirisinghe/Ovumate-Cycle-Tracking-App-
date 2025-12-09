import 'package:easy_localization/easy_localization.dart';

enum ArticleCategory {
  menstrualHealth,
  fertility,
  pregnancy,
  nutrition,
  exercise,
  fitness,
  mentalHealth,
  lifestyle,
  medical,
  general,
  relationships,
  medicalConditions;

  String get categoryDisplayName {
    switch (this) {
      case ArticleCategory.menstrualHealth:
        return 'articles.categories.menstrual_health'.tr();
      case ArticleCategory.fertility:
        return 'articles.categories.fertility'.tr();
      case ArticleCategory.nutrition:
        return 'articles.categories.nutrition'.tr();
      case ArticleCategory.exercise:
        return 'articles.categories.exercise'.tr();
      case ArticleCategory.mentalHealth:
        return 'articles.categories.mental_health'.tr();
      case ArticleCategory.lifestyle:
        return 'articles.categories.lifestyle'.tr();
      case ArticleCategory.medical:
        return 'articles.categories.medical'.tr();
      case ArticleCategory.general:
        return 'articles.categories.general'.tr();
      case ArticleCategory.relationships:
        return 'articles.categories.relationships'.tr();
      case ArticleCategory.pregnancy:
        return 'articles.categories.pregnancy'.tr();
      case ArticleCategory.fitness:
        return 'articles.categories.fitness'.tr();
      case ArticleCategory.medicalConditions:
        return 'articles.categories.medical_conditions'.tr();
    }
  }
}

enum ArticleDifficulty {
  beginner,
  intermediate,
  advanced;

  String get difficultyDisplayName {
    switch (this) {
      case ArticleDifficulty.beginner:
        return 'articles.difficulty.beginner'.tr();
      case ArticleDifficulty.intermediate:
        return 'articles.difficulty.intermediate'.tr();
      case ArticleDifficulty.advanced:
        return 'articles.difficulty.advanced'.tr();
    }
  }
}

class WellnessArticle {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String author;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final List<String> tags;
  final ArticleCategory category;
  final ArticleDifficulty difficulty;
  final String? imageUrl;
  final String? videoUrl;
  final int readTime; // in minutes
  final bool isFeatured;
  final bool isPremium;
  final int viewCount;
  final double rating;
  final int ratingCount;
  final List<String> relatedArticles;

  WellnessArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.author,
    required this.publishedAt,
    required this.updatedAt,
    this.tags = const [],
    required this.category,
    this.difficulty = ArticleDifficulty.beginner,
    this.imageUrl,
    this.videoUrl,
    this.readTime = 5,
    this.isFeatured = false,
    this.isPremium = false,
    this.viewCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.relatedArticles = const [],
  });

  factory WellnessArticle.fromJson(Map<String, dynamic> json) {
    return WellnessArticle(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      publishedAt: DateTime.parse(json['published_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      tags: List<String>.from(json['tags'] ?? []),
      category: ArticleCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ArticleCategory.general,
      ),
      difficulty: ArticleDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => ArticleDifficulty.beginner,
      ),
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      readTime: json['read_time'] ?? 5,
      isFeatured: json['is_featured'] ?? false,
      isPremium: json['is_premium'] ?? false,
      viewCount: json['view_count'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      relatedArticles: List<String>.from(json['related_articles'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'author': author,
      'published_at': publishedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'tags': tags,
      'category': category.toString().split('.').last,
      'difficulty': difficulty.toString().split('.').last,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'read_time': readTime,
      'is_featured': isFeatured,
      'is_premium': isPremium,
      'view_count': viewCount,
      'rating': rating,
      'rating_count': ratingCount,
      'related_articles': relatedArticles,
    };
  }

  WellnessArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? author,
    DateTime? publishedAt,
    DateTime? updatedAt,
    List<String>? tags,
    ArticleCategory? category,
    ArticleDifficulty? difficulty,
    String? imageUrl,
    String? videoUrl,
    int? readTime,
    bool? isFeatured,
    bool? isPremium,
    int? viewCount,
    double? rating,
    int? ratingCount,
    List<String>? relatedArticles,
  }) {
    return WellnessArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      readTime: readTime ?? this.readTime,
      isFeatured: isFeatured ?? this.isFeatured,
      isPremium: isPremium ?? this.isPremium,
      viewCount: viewCount ?? this.viewCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      relatedArticles: relatedArticles ?? this.relatedArticles,
    );
  }

  String get categoryDisplayName {
    return category.categoryDisplayName;
  }

  String get difficultyDisplayName {
    return difficulty.difficultyDisplayName;
  }

  String get readTimeDisplay {
    if (readTime < 1) {
      return 'articles.read_time.less_than_1'.tr();
    } else if (readTime == 1) {
      return 'articles.read_time.one_min'.tr();
    } else {
      return 'articles.read_time.multiple_min'.tr(namedArgs: {'minutes': readTime.toString()});
    }
  }

  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inDays <= 7;
  }

  bool get isNewArticle => isNew;

  double get averageRating => rating;
}

