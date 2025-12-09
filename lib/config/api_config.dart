import 'package:flutter/foundation.dart';

/// API Configuration for external health data sources
/// 
/// For production, these should be stored in environment variables
/// or secure storage, not hardcoded in the app.
class ApiConfig {
  // News API - Get free key from https://newsapi.org/
  static const String newsApiKey = String.fromEnvironment(
    'NEWS_API_KEY',
    defaultValue: 'YOUR_NEWS_API_KEY_HERE',
  );
  
  // CDC API - Register at https://dev.socrata.com/
  static const String cdcAppToken = String.fromEnvironment(
    'CDC_APP_TOKEN',
    defaultValue: 'YOUR_CDC_APP_TOKEN_HERE',
  );
  
  // Health.gov API - No key required, but rate limited
  static const String healthGovApiUrl = 'https://health.gov/myhealthfinder/api/v3/topicsearch.json';
  
  // WHO RSS Feeds - No key required
  static const List<String> whoRssFeeds = [
    'https://www.who.int/feeds/entity/mediacentre/news/en/rss.xml',
    'https://www.who.int/feeds/entity/health-topics/en/rss.xml',
    'https://www.who.int/feeds/entity/women/en/rss.xml',
  ];
  
  // MedlinePlus API - No key required
  static const String medlineApiUrl = 'https://wsearch.nlm.nih.gov/ws/query';
  
  // WebMD RSS - No key required
  static const List<String> webmdRssFeeds = [
    'https://www.webmd.com/rss/rss.aspx?RSSSource=RSS_PUBLIC',
    'https://www.webmd.com/rss/rss.aspx?RSSSource=RSS_WOMENS_HEALTH',
  ];
  
  // PubMed API - No key required
  static const String pubmedApiUrl = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
  
  // Rate limiting configuration
  static const Duration newsApiRateLimit = Duration(minutes: 1); // 1000 requests/day free
  static const Duration cdcApiRateLimit = Duration(seconds: 30); // 1000 requests/hour
  static const Duration healthGovRateLimit = Duration(seconds: 10); // Conservative limit
  
  // API endpoints with proper parameters
  static String getNewsApiUrl({
    required String query,
    String language = 'en',
    String sortBy = 'publishedAt',
    int pageSize = 20,
  }) {
    return 'https://newsapi.org/v2/everything'
        '?q=$query'
        '&language=$language'
        '&sortBy=$sortBy'
        '&pageSize=$pageSize'
        '&apiKey=$newsApiKey';
  }
  
  static String getCdcApiUrl({
    required String topic,
    int limit = 20,
  }) {
    return 'https://tools.cdc.gov/api/v2/resources/media'
        '?topic=$topic'
        '&limit=$limit'
        '&app_token=$cdcAppToken';
  }
  
  static String getPubMedApiUrl({
    required String query,
    String database = 'pubmed',
    int maxResults = 20,
  }) {
    return '$pubmedApiUrl/esearch.fcgi'
        '?db=$database'
        '&term=$query'
        '&retmax=$maxResults'
        '&retmode=json';
  }
  
  // Check if APIs are properly configured
  static bool get isNewsApiConfigured => 
      newsApiKey != 'YOUR_NEWS_API_KEY_HERE' && newsApiKey.isNotEmpty;
  
  static bool get isCdcApiConfigured => 
      cdcAppToken != 'YOUR_CDC_APP_TOKEN_HERE' && cdcAppToken.isNotEmpty;
  
  static bool get isAnyApiConfigured => 
      isNewsApiConfigured || isCdcApiConfigured;
  
  // Get API status for debugging
  static Map<String, bool> get apiStatus => {
    'News API': isNewsApiConfigured,
    'CDC API': isCdcApiConfigured,
    'Health.gov': true, // Always available
    'WHO RSS': true, // Always available
    'MedlinePlus': true, // Always available
    'WebMD RSS': true, // Always available
    'PubMed': true, // Always available
  };
  
  // Print API configuration status (for debugging)
  static void printApiStatus() {
    if (kDebugMode) {
      print('=== API Configuration Status ===');
      apiStatus.forEach((api, configured) {
        print('$api: ${configured ? '✅ Configured' : '❌ Not Configured'}');
      });
      print('===============================');
    }
  }
}
