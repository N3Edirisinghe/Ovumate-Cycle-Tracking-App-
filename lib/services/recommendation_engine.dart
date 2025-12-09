import 'dart:math';
import 'package:ovumate/models/wellness_article.dart';
import 'package:ovumate/models/article_engagement.dart';
import 'package:ovumate/models/user_profile.dart';

/// Advanced recommendation engine using ML concepts
class RecommendationEngine {
  static const double _collaborativeWeight = 0.3;
  static const double _contentWeight = 0.4;
  static const double _behaviorWeight = 0.3;
  
  /// Get personalized recommendations using hybrid approach
  static List<WellnessArticle> getHybridRecommendations({
    required List<WellnessArticle> articles,
    required UserProfile userProfile,
    required List<ArticleEngagement> userEngagements,
    required List<ArticleEngagement> allEngagements,
    int limit = 10,
  }) {
    // Get different types of recommendations
    final collaborativeRecs = _getCollaborativeRecommendations(
      articles, userProfile, userEngagements, allEngagements, limit: limit,
    );
    
    final contentRecs = _getContentBasedRecommendations(
      articles, userProfile, userEngagements, limit: limit,
    );
    
    final behaviorRecs = _getBehaviorBasedRecommendations(
      articles, userProfile, userEngagements, limit: limit,
    );
    
    // Combine and score recommendations
    final combinedRecs = _combineRecommendations(
      collaborativeRecs, contentRecs, behaviorRecs, limit: limit,
    );
    
    return combinedRecs;
  }
  
  /// Collaborative filtering: Find similar users and recommend their liked articles
  static List<WellnessArticle> _getCollaborativeRecommendations(
    List<WellnessArticle> articles,
    UserProfile userProfile,
    List<ArticleEngagement> userEngagements,
    List<ArticleEngagement> allEngagements,
    {int limit = 10}
  ) {
    // Find similar users based on demographics and preferences
    final similarUsers = _findSimilarUsers(userProfile, allEngagements);
    
    // Get articles liked by similar users
    final similarUserLikes = <String, double>{};
    
    for (final similarUser in similarUsers) {
      final userEngagement = allEngagements
          .where((e) => e.userId == similarUser['userId'])
          .where((e) => e.rating != null && e.rating! >= 4.0)
          .toList();
      
      for (final engagement in userEngagement) {
        final articleId = engagement.articleId;
        final similarity = similarUser['similarity'] as double;
        final rating = engagement.rating!;
        
        similarUserLikes[articleId] = (similarUserLikes[articleId] ?? 0.0) + (similarity * rating);
      }
    }
    
    // Sort by score and get top articles
    final sortedArticleIds = similarUserLikes.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    final recommendedArticles = <WellnessArticle>[];
    for (final entry in sortedArticleIds.take(limit)) {
      final article = articles.firstWhere(
        (a) => a.id == entry.key,
        orElse: () => articles.first,
      );
      if (article != articles.first) {
        recommendedArticles.add(article);
      }
    }
    
    return recommendedArticles;
  }
  
  /// Content-based filtering: Recommend articles similar to user's interests
  static List<WellnessArticle> _getContentBasedRecommendations(
    List<WellnessArticle> articles,
    UserProfile userProfile,
    List<ArticleEngagement> userEngagements,
    {int limit = 10}
  ) {
    // Build user interest profile
    final userInterests = _buildUserInterestProfile(userProfile, userEngagements);
    
    // Score articles based on content similarity
    final scoredArticles = articles.map((article) {
      double score = 0.0;
      
      // Category preference
      if (userInterests['categories'].contains(article.category.toString())) {
        score += 3.0;
      }
      
      // Tag matching
      for (final tag in article.tags) {
        if (userInterests['tags'].contains(tag.toLowerCase())) {
          score += 2.0;
        }
      }
      
      // Author preference
      if (userInterests['authors'].contains(article.authorName.toLowerCase())) {
        score += 1.5;
      }
      
      // Difficulty preference
      if (userInterests['preferredDifficulty'] == article.difficulty.toString()) {
        score += 1.0;
      }
      
      // Reading time preference
      final preferredTime = userInterests['preferredReadingTime'] as int;
      final articleTime = article.readingTimeMinutes;
      if ((articleTime - preferredTime).abs() <= 2) {
        score += 1.0;
      }
      
      return MapEntry(article, score);
    }).toList();
    
    // Sort by score and return top articles
    scoredArticles.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredArticles
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Behavior-based filtering: Use user's reading patterns and engagement
  static List<WellnessArticle> _getBehaviorBasedRecommendations(
    List<WellnessArticle> articles,
    UserProfile userProfile,
    List<ArticleEngagement> userEngagements,
    {int limit = 10}
  ) {
    // Analyze user behavior patterns
    final behaviorPatterns = _analyzeUserBehavior(userEngagements);
    
    // Score articles based on behavior patterns
    final scoredArticles = articles.map((article) {
      double score = 0.0;
      
      // Reading time pattern
      final avgReadTime = behaviorPatterns['avgReadTime'] as double;
      if ((article.readingTimeMinutes - avgReadTime).abs() <= 3) {
        score += 2.0;
      }
      
      // Category engagement pattern
      final categoryEngagement = behaviorPatterns['categoryEngagement'] as Map<String, double>;
      final categoryScore = categoryEngagement[article.category.toString()] ?? 0.0;
      score += categoryScore * 2.0;
      
      // Time of day preference
      final currentHour = DateTime.now().hour;
      final preferredHours = behaviorPatterns['preferredReadingHours'] as List<int>;
      if (preferredHours.contains(currentHour)) {
        score += 1.0;
      }
      
      // Engagement frequency pattern
      final engagementFrequency = behaviorPatterns['engagementFrequency'] as double;
      if (engagementFrequency > 0.7) {
        score += 1.0; // High engagement users get variety
      } else {
        score += 0.5; // Low engagement users get safe bets
      }
      
      return MapEntry(article, score);
    }).toList();
    
    // Sort by score and return top articles
    scoredArticles.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredArticles
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Combine different recommendation types with weights
  static List<WellnessArticle> _combineRecommendations(
    List<WellnessArticle> collaborativeRecs,
    List<WellnessArticle> contentRecs,
    List<WellnessArticle> behaviorRecs,
    {int limit = 10}
  ) {
    final combinedScores = <String, double>{};
    
    // Score collaborative recommendations
    for (int i = 0; i < collaborativeRecs.length; i++) {
      final articleId = collaborativeRecs[i].id;
      final score = _collaborativeWeight * (1.0 - (i / collaborativeRecs.length));
      combinedScores[articleId] = (combinedScores[articleId] ?? 0.0) + score;
    }
    
    // Score content-based recommendations
    for (int i = 0; i < contentRecs.length; i++) {
      final articleId = contentRecs[i].id;
      final score = _contentWeight * (1.0 - (i / contentRecs.length));
      combinedScores[articleId] = (combinedScores[articleId] ?? 0.0) + score;
    }
    
    // Score behavior-based recommendations
    for (int i = 0; i < behaviorRecs.length; i++) {
      final articleId = behaviorRecs[i].id;
      final score = _behaviorWeight * (1.0 - (i / behaviorRecs.length));
      combinedScores[articleId] = (combinedScores[articleId] ?? 0.0) + score;
    }
    
    // Sort by combined score and return top articles
    final sortedArticleIds = combinedScores.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    // Get articles in order
    final allArticles = <WellnessArticle>[];
    allArticles.addAll(collaborativeRecs);
    allArticles.addAll(contentRecs);
    allArticles.addAll(behaviorRecs);
    
    final recommendedArticles = <WellnessArticle>[];
    final seenIds = <String>{};
    
    for (final entry in sortedArticleIds.take(limit)) {
      final article = allArticles.firstWhere((a) => a.id == entry.key);
      if (!seenIds.contains(article.id)) {
        recommendedArticles.add(article);
        seenIds.add(article.id);
      }
    }
    
    return recommendedArticles;
  }
  
  /// Find similar users based on demographics and preferences
  static List<Map<String, dynamic>> _findSimilarUsers(
    UserProfile userProfile,
    List<ArticleEngagement> allEngagements,
  ) {
    final similarUsers = <Map<String, dynamic>>[];
    
    // Group engagements by user
    final userEngagements = <String, List<ArticleEngagement>>{};
    for (final engagement in allEngagements) {
      userEngagements.putIfAbsent(engagement.userId, () => []).add(engagement);
    }
    
    // Calculate similarity with each user
    for (final entry in userEngagements.entries) {
      if (entry.key == userProfile.id) continue; // Skip self
      
      final similarity = _calculateUserSimilarity(userProfile, entry.value);
      if (similarity > 0.3) { // Only include users with >30% similarity
        similarUsers.add({
          'userId': entry.key,
          'similarity': similarity,
        });
      }
    }
    
    // Sort by similarity
    similarUsers.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
    
    return similarUsers.take(10).toList(); // Top 10 similar users
  }
  
  /// Calculate similarity between two users
  static double _calculateUserSimilarity(
    UserProfile userProfile,
    List<ArticleEngagement> otherUserEngagements,
  ) {
    double similarity = 0.0;
    int factors = 0;
    
    // Age similarity (closer age = higher similarity)
    final ageDiff = (userProfile.age - 25).abs(); // Assume average age 25
    final ageSimilarity = 1.0 / (1.0 + ageDiff / 10.0);
    similarity += ageSimilarity;
    factors++;
    
    // Category preference similarity
    final userCategories = userProfile.wellnessGoals;
    final otherUserCategories = otherUserEngagements
        .where((e) => e.rating != null && e.rating! >= 4.0)
        .map((e) => e.tags)
        .expand((tags) => tags)
        .toSet();
    
    if (userCategories.isNotEmpty && otherUserCategories.isNotEmpty) {
      final intersection = userCategories.where((c) => otherUserCategories.contains(c)).length;
      final union = userCategories.length + otherUserCategories.length - intersection;
      final categorySimilarity = intersection / union;
      similarity += categorySimilarity;
      factors++;
    }
    
    // Reading difficulty preference
    // This would require tracking user's preferred difficulty level
    
    return factors > 0 ? similarity / factors : 0.0;
  }
  
  /// Build user interest profile from profile and engagements
  static Map<String, dynamic> _buildUserInterestProfile(
    UserProfile userProfile,
    List<ArticleEngagement> userEngagements,
  ) {
    final interests = <String, dynamic>{
      'categories': <String>{},
      'tags': <String>{},
      'authors': <String>{},
      'preferredDifficulty': 'beginner',
      'preferredReadingTime': 5,
    };
    
    // Add profile-based interests
    interests['categories'].addAll(userProfile.wellnessGoals);
    
    // Add engagement-based interests
    for (final engagement in userEngagements) {
      if (engagement.rating != null && engagement.rating! >= 4.0) {
        interests['tags'].addAll(engagement.tags);
      }
    }
    
    // Analyze reading patterns
    final readArticles = userEngagements.where((e) => e.isRead).toList();
    if (readArticles.isNotEmpty) {
      final avgReadTime = readArticles
          .map((e) => e.readDuration)
          .reduce((a, b) => a + b) / readArticles.length;
      
      interests['preferredReadingTime'] = (avgReadTime / 60).round(); // Convert to minutes
    }
    
    return interests;
  }
  
  /// Analyze user behavior patterns
  static Map<String, dynamic> _analyzeUserBehavior(
    List<ArticleEngagement> userEngagements,
  ) {
    final patterns = <String, dynamic>{
      'avgReadTime': 0.0,
      'categoryEngagement': <String, double>{},
      'preferredReadingHours': <int>[],
      'engagementFrequency': 0.0,
    };
    
    if (userEngagements.isEmpty) return patterns;
    
    // Calculate average read time
    final readEngagements = userEngagements.where((e) => e.isRead).toList();
    if (readEngagements.isNotEmpty) {
      final totalReadTime = readEngagements
          .map((e) => e.readDuration)
          .reduce((a, b) => a + b);
      patterns['avgReadTime'] = totalReadTime / readEngagements.length;
    }
    
    // Calculate category engagement
    final categoryCounts = <String, int>{};
    final categoryRatings = <String, double>{};
    
    for (final engagement in userEngagements) {
      if (engagement.rating != null) {
        // This would require mapping article ID to category
        // For now, using tags as proxy
        for (final tag in engagement.tags) {
          categoryCounts[tag] = (categoryCounts[tag] ?? 0) + 1;
          categoryRatings[tag] = (categoryRatings[tag] ?? 0.0) + engagement.rating!;
        }
      }
    }
    
    for (final entry in categoryCounts.entries) {
      final avgRating = categoryRatings[entry.key]! / entry.value;
      patterns['categoryEngagement'][entry.key] = avgRating;
    }
    
    // Calculate engagement frequency (engagements per day)
    final firstEngagement = userEngagements
        .map((e) => e.createdAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    
    final daysSinceFirst = DateTime.now().difference(firstEngagement).inDays;
    patterns['engagementFrequency'] = userEngagements.length / (daysSinceFirst + 1);
    
    // Preferred reading hours (simplified)
    patterns['preferredReadingHours'] = [9, 12, 18, 21]; // Common reading times
    
    return patterns;
  }
  
  /// Get trending articles based on global engagement
  static List<WellnessArticle> getTrendingArticles(
    List<WellnessArticle> articles,
    List<ArticleEngagement> allEngagements,
    {int limit = 10}
  ) {
    // Calculate trending score for each article
    final trendingScores = <String, double>{};
    
    for (final article in articles) {
      final articleEngagements = allEngagements
          .where((e) => e.articleId == article.id)
          .toList();
      
      if (articleEngagements.isEmpty) continue;
      
      double score = 0.0;
      
      // Engagement volume
      score += articleEngagements.length * 0.5;
      
      // Average rating
      final ratings = articleEngagements
          .where((e) => e.rating != null)
          .map((e) => e.rating!)
          .toList();
      
      if (ratings.isNotEmpty) {
        final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
        score += avgRating * 2.0;
      }
      
      // Recent engagement bonus
      final recentEngagements = articleEngagements
          .where((e) => DateTime.now().difference(e.createdAt).inDays <= 7)
          .length;
      
      score += recentEngagements * 1.5;
      
      // Bookmark bonus
      final bookmarks = articleEngagements
          .where((e) => e.isBookmarked)
          .length;
      
      score += bookmarks * 2.0;
      
      trendingScores[article.id] = score;
    }
    
    // Sort by trending score
    final sortedArticleIds = trendingScores.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    // Return top trending articles
    final trendingArticles = <WellnessArticle>[];
    for (final entry in sortedArticleIds.take(limit)) {
      final article = articles.firstWhere((a) => a.id == entry.key);
      trendingArticles.add(article);
    }
    
    return trendingArticles;
  }
  
  /// Get diversity recommendations (different from user's usual preferences)
  static List<WellnessArticle> getDiversityRecommendations(
    List<WellnessArticle> articles,
    UserProfile userProfile,
    List<ArticleEngagement> userEngagements,
    {int limit = 5}
  ) {
    // Get user's usual preferences
    final usualCategories = userProfile.wellnessGoals;
    final usualTags = userEngagements
        .where((e) => e.rating != null && e.rating! >= 4.0)
        .map((e) => e.tags)
        .expand((tags) => tags)
        .toSet();
    
    // Find articles that are different from usual preferences
    final diversityScores = articles.map((article) {
      double diversityScore = 0.0;
      
      // Category diversity
      if (!usualCategories.contains(article.category.toString())) {
        diversityScore += 3.0;
      }
      
      // Tag diversity
      final newTags = article.tags.where((tag) => !usualTags.contains(tag)).length;
      diversityScore += newTags * 0.5;
      
      // Difficulty diversity
      if (article.difficulty != ArticleDifficulty.beginner) {
        diversityScore += 1.0;
      }
      
      // Reading time diversity
      if (article.readingTimeMinutes > 8) {
        diversityScore += 1.0;
      }
      
      return MapEntry(article, diversityScore);
    }).toList();
    
    // Sort by diversity score
    diversityScores.sort((a, b) => b.value.compareTo(a.value));
    
    return diversityScores
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
}
