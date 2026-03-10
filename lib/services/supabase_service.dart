import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/models/user_profile.dart';
import 'package:ovumate/models/wellness_article.dart';
import 'package:ovumate/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'dart:async';

// Re-export MessageSender for convenience
export 'package:ovumate/models/chat_message.dart' show MessageSender;

/// Centralized Supabase service for all database operations
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Check if user is authenticated
  bool get isAuthenticated => client.auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => client.auth.currentUser?.id;

  // ========== USER PROFILE OPERATIONS ==========

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      debugPrint('🔍 Getting user profile for userId: $userId');
      
      // Check connection first
      if (!await checkConnection()) {
        debugPrint('⚠️ Database connection failed - returning null');
        return null;
      }

      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ User profile not found for userId: $userId');
        return null;
      }
      
      debugPrint('✅ User profile found in database');
      try {
        final profile = UserProfile.fromJson(response as Map<String, dynamic>);
        debugPrint('✅ User profile parsed successfully');
        debugPrint('   Email: ${profile.email}');
        debugPrint('   Created: ${profile.createdAt}');
        return profile;
      } catch (parseError) {
        debugPrint('❌ Error parsing user profile: $parseError');
        debugPrint('   Response data: $response');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      // Return null instead of rethrowing for better UX
      if (e.toString().contains('connection') || e.toString().contains('network')) {
        debugPrint('⚠️ Network error - returning null');
        return null;
      }
      // For other errors, also return null to prevent app crash
      return null;
    }
  }

  /// Create or update user profile
  Future<UserProfile> upsertUserProfile(UserProfile profile) async {
    try {
      // Check connection first
      if (!await checkConnection()) {
        throw Exception('Database connection failed');
      }

      final response = await client
          .from('user_profiles')
          .upsert(profile.toJson())
          .select()
          .single();

      return UserProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error upserting user profile: $e');
      // Re-throw for critical operations like profile creation
      rethrow;
    }
  }

  /// Update user profile
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    try {
      // Check connection first
      if (!await checkConnection()) {
        throw Exception('Database connection failed');
      }

      final response = await client
          .from('user_profiles')
          .update(profile.toJson())
          .eq('id', profile.id)
          .select()
          .single();

      return UserProfile.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // ========== CYCLE ENTRIES OPERATIONS ==========

  /// Get all cycle entries for a user
  Future<List<CycleEntry>> getCycleEntries(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Check connection first
      if (!await checkConnection()) {
        throw Exception('Database connection failed');
      }

      var query = client
          .from('cycle_entries')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);
      
      if (response == null) return [];
      
      return (response as List)
          .map((json) => CycleEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting cycle entries: $e');
      // Return empty list instead of rethrowing for better UX
      if (e.toString().contains('connection') || e.toString().contains('network')) {
        debugPrint('Network error - returning empty list');
        return [];
      }
      rethrow;
    }
  }

  /// Get cycle entry by ID
  Future<CycleEntry?> getCycleEntry(String entryId) async {
    try {
      final response = await client
          .from('cycle_entries')
          .select()
          .eq('id', entryId)
          .maybeSingle();

      if (response == null) return null;
      return CycleEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error getting cycle entry: $e');
      rethrow;
    }
  }

  /// Add new cycle entry
  Future<CycleEntry> addCycleEntry(CycleEntry entry) async {
    try {
      // Convert CycleEntry to database format
      final entryJson = entry.toJson();
      // Database uses DATE type (YYYY-MM-DD format)
      entryJson['date'] = entry.date.toIso8601String().split('T')[0];
      // Convert timestamps to ISO strings
      entryJson['created_at'] = entry.createdAt.toIso8601String();
      entryJson['updated_at'] = entry.updatedAt.toIso8601String();
      // Convert phase enum to string
      entryJson['phase'] = entry.phase.toString().split('.').last;
      // Convert symptom severity map
      if (entryJson['symptom_severity'] is Map) {
        final severityMap = entryJson['symptom_severity'] as Map;
        entryJson['symptom_severity'] = Map.fromEntries(
          severityMap.entries.map((e) => MapEntry(e.key, e.value.toString().split('.').last)),
        );
      }

      final response = await client
          .from('cycle_entries')
          .insert(entryJson)
          .select()
          .single();

      return CycleEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error adding cycle entry: $e');
      rethrow;
    }
  }

  /// Update cycle entry
  Future<CycleEntry> updateCycleEntry(CycleEntry entry) async {
    try {
      final entryJson = entry.toJson();
      // Database uses DATE type (YYYY-MM-DD format)
      entryJson['date'] = entry.date.toIso8601String().split('T')[0];
      // Convert timestamps to ISO strings
      entryJson['updated_at'] = entry.updatedAt.toIso8601String();
      // Convert phase enum to string
      entryJson['phase'] = entry.phase.toString().split('.').last;
      // Convert symptom severity map
      if (entryJson['symptom_severity'] is Map) {
        final severityMap = entryJson['symptom_severity'] as Map;
        entryJson['symptom_severity'] = Map.fromEntries(
          severityMap.entries.map((e) => MapEntry(e.key, e.value.toString().split('.').last)),
        );
      }

      final response = await client
          .from('cycle_entries')
          .update(entryJson)
          .eq('id', entry.id)
          .select()
          .single();

      return CycleEntry.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error updating cycle entry: $e');
      rethrow;
    }
  }

  /// Delete cycle entry
  Future<void> deleteCycleEntry(String entryId) async {
    try {
      await client
          .from('cycle_entries')
          .delete()
          .eq('id', entryId);
    } catch (e) {
      debugPrint('Error deleting cycle entry: $e');
      rethrow;
    }
  }

  /// Get period entries for a user
  Future<List<CycleEntry>> getPeriodEntries(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Check connection first
      if (!await checkConnection()) {
        throw Exception('Database connection failed');
      }

      var query = client
          .from('cycle_entries')
          .select()
          .eq('user_id', userId)
          .eq('is_period_day', true);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);
      
      if (response == null) return [];
      
      return (response as List)
          .map((json) => CycleEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting period entries: $e');
      // Return empty list instead of rethrowing for better UX
      if (e.toString().contains('connection') || e.toString().contains('network')) {
        debugPrint('Network error - returning empty list');
        return [];
      }
      rethrow;
    }
  }

  // ========== WELLNESS ARTICLES OPERATIONS ==========

  /// Get all wellness articles
  Future<List<WellnessArticle>> getWellnessArticles({
    ArticleCategory? category,
    ArticleDifficulty? difficulty,
    bool? isFeatured,
    bool? isNew,
    int? limit,
  }) async {
    try {
      // Check connection first
      if (!await checkConnection()) {
        throw Exception('Database connection failed');
      }

      var query = client
          .from('wellness_articles')
          .select();

      if (category != null) {
        query = query.eq('category', category.toString().split('.').last);
      }

      if (difficulty != null) {
        query = query.eq('difficulty', difficulty.toString().split('.').last);
      }

      if (isFeatured != null) {
        query = query.eq('is_featured', isFeatured);
      }

      if (isNew != null) {
        query = query.eq('is_new', isNew);
      }

      // Order and limit must be applied after filters
      var orderedQuery = query.order('created_at', ascending: false);
      
      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final response = await orderedQuery;
      
      if (response == null) return [];
      
      // Convert database format to model format
      return (response as List)
          .map((json) {
            final articleJson = json as Map<String, dynamic>;
            // Database uses 'created_at', model uses 'published_at'
            if (articleJson['created_at'] != null && articleJson['published_at'] == null) {
              articleJson['published_at'] = articleJson['created_at'];
            }
            // Handle missing fields
            if (articleJson['view_count'] == null) articleJson['view_count'] = articleJson['views_count'] ?? 0;
            if (articleJson['rating_count'] == null) articleJson['rating_count'] = 0;
            if (articleJson['related_articles'] == null) articleJson['related_articles'] = [];
            if (articleJson['is_new'] == null) {
              // Calculate is_new based on created_at
              final createdAt = DateTime.parse(articleJson['created_at']);
              final daysDiff = DateTime.now().difference(createdAt).inDays;
              articleJson['is_new'] = daysDiff <= 7;
            }
            return WellnessArticle.fromJson(articleJson);
          })
          .toList();
    } catch (e) {
      debugPrint('Error getting wellness articles: $e');
      // Return empty list instead of rethrowing for better UX
      if (e.toString().contains('connection') || e.toString().contains('network')) {
        debugPrint('Network error - returning empty list');
        return [];
      }
      rethrow;
    }
  }

  /// Get wellness article by ID
  Future<WellnessArticle?> getWellnessArticle(String articleId) async {
    try {
      final response = await client
          .from('wellness_articles')
          .select()
          .eq('id', articleId)
          .maybeSingle();

      if (response == null) return null;
      
      // Convert database format to model format
      final json = response as Map<String, dynamic>;
      // Database uses 'created_at', model uses 'published_at'
      if (json['created_at'] != null && json['published_at'] == null) {
        json['published_at'] = json['created_at'];
      }
      
      return WellnessArticle.fromJson(json);
    } catch (e) {
      debugPrint('Error getting wellness article: $e');
      rethrow;
    }
  }

  /// Get user's article progress
  Future<Map<String, dynamic>?> getArticleProgress(String userId, String articleId) async {
    try {
      final response = await client
          .from('user_article_progress')
          .select()
          .eq('user_id', userId)
          .eq('article_id', articleId)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error getting article progress: $e');
      rethrow;
    }
  }

  /// Update article progress
  Future<void> updateArticleProgress({
    required String userId,
    required String articleId,
    bool? isRead,
    bool? isBookmarked,
    double? readProgress,
  }) async {
    try {
      final progressData = <String, dynamic>{
        'user_id': userId,
        'article_id': articleId,
        'last_read_at': DateTime.now().toIso8601String(),
      };

      if (isRead != null) progressData['is_read'] = isRead;
      if (isBookmarked != null) progressData['is_bookmarked'] = isBookmarked;
      if (readProgress != null) progressData['read_progress'] = readProgress;

      await client
          .from('user_article_progress')
          .upsert(progressData);
    } catch (e) {
      debugPrint('Error updating article progress: $e');
      rethrow;
    }
  }

  /// Rate an article
  Future<void> rateArticle({
    required String userId,
    required String articleId,
    required double rating,
  }) async {
    try {
      await client
          .from('article_ratings')
          .upsert({
            'user_id': userId,
            'article_id': articleId,
            'rating': rating,
          });
    } catch (e) {
      debugPrint('Error rating article: $e');
      rethrow;
    }
  }

  // ========== CHAT MESSAGES OPERATIONS ==========

  /// Get chat messages for a user
  Future<List<ChatMessage>> getChatMessages(String userId, {int? limit}) async {
    try {
      var query = client
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      
      // Convert database format to model format and reverse to show oldest first
      final messages = (response as List)
          .map((json) {
            final messageJson = json as Map<String, dynamic>;
            // Database uses 'is_user_message' (boolean), model uses 'sender' (enum)
            messageJson['sender'] = messageJson['is_user_message'] == true 
                ? 'user' 
                : 'bot';
            // Map message_type to type
            messageJson['type'] = messageJson['message_type'] ?? 'text';
            // Add default values for missing fields
            messageJson['is_read'] = messageJson['is_read'] ?? false;
            messageJson['quick_replies'] = messageJson['quick_replies'] ?? null;
            messageJson['suggestions'] = messageJson['suggestions'] ?? null;
            return ChatMessage.fromJson(messageJson);
          })
          .toList();
      
      return messages.reversed.toList();
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      rethrow;
    }
  }

  /// Add chat message
  Future<ChatMessage> addChatMessage(ChatMessage message) async {
    try {
      // Convert model format to database format
      final messageJson = message.toJson();
      // Database uses 'is_user_message' (boolean), model uses 'sender' (enum)
      messageJson['is_user_message'] = message.sender == MessageSender.user;
      messageJson.remove('sender'); // Remove sender as it's not in database
      
      // Map message_type from model type
      messageJson['message_type'] = message.type.toString().split('.').last;
      
      final response = await client
          .from('chat_messages')
          .insert(messageJson)
          .select()
          .single();

      // Convert database format back to model format
      final responseJson = response as Map<String, dynamic>;
      responseJson['sender'] = responseJson['is_user_message'] == true 
          ? 'user' 
          : 'bot';
      responseJson['type'] = responseJson['message_type'] ?? 'text';
      
      return ChatMessage.fromJson(responseJson);
    } catch (e) {
      debugPrint('Error adding chat message: $e');
      rethrow;
    }
  }

  /// Delete chat messages for a user
  Future<void> deleteChatMessages(String userId) async {
    try {
      await client
          .from('chat_messages')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting chat messages: $e');
      rethrow;
    }
  }

  // ========== UTILITY METHODS ==========

  /// Check database connection
  Future<bool> checkConnection() async {
    try {
      // Try a simple query with timeout
      await client
          .from('user_profiles')
          .select()
          .limit(1)
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Connection check timed out');
      });
      return true;
    } on TimeoutException {
      debugPrint('Database connection check timed out');
      return false;
    } catch (e) {
      debugPrint('Database connection check failed: $e');
      // Check if it's a network error
      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('connection') ||
          e.toString().contains('network')) {
        debugPrint('Network error detected');
      }
      return false;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getStatistics(String userId) async {
    try {
      final cycleEntries = await getCycleEntries(userId);
      final periodEntries = await getPeriodEntries(userId);
      final messages = await getChatMessages(userId);

      return {
        'total_entries': cycleEntries.length,
        'period_entries': periodEntries.length,
        'chat_messages': messages.length,
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {};
    }
  }
}

