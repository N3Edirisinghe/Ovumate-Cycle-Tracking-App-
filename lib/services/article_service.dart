import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovumate/models/wellness_article.dart';
import 'package:ovumate/config/api_config.dart';
import 'package:flutter/foundation.dart';

class ArticleService {
  // Rate limiting and request tracking
  static final Map<String, DateTime> _lastRequestTimes = {};
  static final Map<String, int> _requestCounts = {};
  
  // Cache configuration
  static const Duration _defaultCacheDuration = Duration(hours: 12);
  static const Duration _newsCacheDuration = Duration(hours: 6);
  static const Duration _cdcCacheDuration = Duration(hours: 24);
  
  static const String _lastUpdateKey = 'last_articles_update';
  static const String _cachedArticlesKey = 'cached_articles';
  
  /// Check if articles need to be updated (daily check)
  static Future<bool> shouldUpdateArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUpdate = prefs.getString(_lastUpdateKey);
    
    if (lastUpdate == null) return true;
    
    final lastUpdateDate = DateTime.parse(lastUpdate);
    final now = DateTime.now();
    final difference = now.difference(lastUpdateDate).inHours;
    
    // Update if more than 12 hours have passed
    return difference >= 12;
  }
  
  /// Get current language from SharedPreferences
  static Future<String> _getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_language') ?? 'en';
    } catch (e) {
      return 'en';
    }
  }

  /// Fetch latest health articles from multiple sources
  static Future<List<WellnessArticle>> fetchLatestArticles() async {
    List<WellnessArticle> allArticles = [];
    
    try {
      // Get current language
      final currentLang = await _getCurrentLanguage();
      
      // Fetch from multiple sources in parallel for better performance
      final futures = [
        if (ApiConfig.isNewsApiConfigured) _fetchNewsAPIArticles(),
        _fetchHealthGovArticles(),
        _fetchMedlineArticles(),
        _fetchCDCArticles(),
        _fetchWHOArticles(),
        _fetchWebMDArticles(),
      ];
      
      final results = await Future.wait(futures);
      
      // Combine all articles
      for (final articleList in results) {
        allArticles.addAll(articleList);
      }
      
      // Add default articles for guaranteed content in current language
      final defaultArticles = _getDefaultArticles(currentLang);
      allArticles.addAll(defaultArticles);
      
      // Remove duplicates by title and sort by publish date
      allArticles = _removeDuplicatesAndSort(allArticles);
      
      // Apply content filtering and categorization
      allArticles = _improveContentCategorization(allArticles);
      
      // Cache articles and update timestamp
      await _cacheArticles(allArticles);
      await _updateLastFetchTime();
      
      return allArticles;
    } catch (e) {
      print('Error fetching articles: $e');
      // Return cached articles or default articles
      return await _getCachedArticles();
    }
  }
  
  /// Fetch articles from News API with rate limiting
  static Future<List<WellnessArticle>> _fetchNewsAPIArticles() async {
    if (!ApiConfig.isNewsApiConfigured) {
      if (kDebugMode) {
        print('News API not configured. Get free key from https://newsapi.org/');
      }
      return [];
    }
    
    // Check rate limiting
    if (!_canMakeRequest('news_api', ApiConfig.newsApiRateLimit)) {
      if (kDebugMode) {
        print('News API rate limit reached. Waiting...');
      }
      return [];
    }
    
    final url = ApiConfig.getNewsApiUrl(
      query: 'women health menstrual cycle fertility pregnancy',
      pageSize: 20,
    );
    
    _trackRequest('news_api');
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final articles = data['articles'] as List;
        
                final wellnessArticles = articles.map((article) => WellnessArticle(
          id: DateTime.now().millisecondsSinceEpoch.toString() + article['title'].hashCode.toString(),
          title: (article['title'] ?? 'Health Article') as String,
          summary: (article['description'] ?? '') as String,
          content: (article['content'] ?? article['description'] ?? '') as String,
          category: ArticleCategory.general,
          difficulty: ArticleDifficulty.beginner,
          readTime: _calculateReadingTime(article['content'] ?? ''),
          imageUrl: article['urlToImage'] as String?,
          tags: ['health', 'women', 'wellness'],
          author: (article['source']['name'] ?? 'Health News') as String,
          publishedAt: DateTime.tryParse(article['publishedAt'] ?? '') ?? DateTime.now(),
          updatedAt: DateTime.now(),
          isFeatured: false,
        )).toList();
        return wellnessArticles;
      }
    } catch (e) {
      print('Error fetching News API articles: $e');
    }
    
    return [];
  }
  
  /// Fetch articles from Health.gov
  static Future<List<WellnessArticle>> _fetchHealthGovArticles() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.healthGovApiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['Result'];
        
        // Handle both List and Map responses from Health.gov API
        List<dynamic> resources;
        if (result is List) {
          resources = result;
        } else if (result is Map && result['Resources'] != null && result['Resources'] is List) {
          resources = result['Resources'] as List;
        } else {
          // No valid resources found
          return [];
        }
        
        return resources.take(5).map((resource) => WellnessArticle(
          id: (resource['Id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString()) as String,
          title: (resource['Title'] ?? 'Health Guide') as String,
          summary: _cleanHtmlText(resource['Sections']?.first?['Description'] ?? '') as String,
          content: _buildContentFromSections(resource['Sections'] ?? []) as String,
          category: _getCategoryFromTopics(resource['Topics'] ?? []),
          difficulty: ArticleDifficulty.intermediate,
          readTime: _calculateReadingTime(_buildContentFromSections(resource['Sections'] ?? [])),
          imageUrl: null,
          tags: _getTagsFromTopics(resource['Topics'] ?? []),
          author: 'Health.gov' as String,
          publishedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFeatured: true,
        )).toList();
      }
    } catch (e) {
      print('Error fetching Health.gov articles: $e');
    }
    
    return [];
  }
  
  /// Fetch articles from MedlinePlus
  static Future<List<WellnessArticle>> _fetchMedlineArticles() async {
    const queries = ['women health', 'menstrual cycle', 'reproductive health'];
    List<WellnessArticle> articles = [];
    
    for (String query in queries) {
      try {
        final url = '${ApiConfig.medlineApiUrl}?db=healthTopics&term=$query&retmax=3&rettype=json';
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          // Note: MedlinePlus API returns XML, this is a simplified example
          // In a real implementation, you'd parse XML and extract proper data
          final content = response.body;
          
          if (content.isNotEmpty) {
            articles.add(WellnessArticle(
              id: (DateTime.now().millisecondsSinceEpoch.toString() + query.hashCode.toString()) as String,
              title: 'Understanding ${query.replaceAll(' ', ' and ')}' as String,
              summary: 'Comprehensive guide about $query from trusted medical sources.' as String,
              content: ('This article provides evidence-based information about $query. '
                      'It covers important aspects of women\'s health and wellness. '
                      'Always consult with healthcare providers for personalized advice.') as String,
              category: query.contains('menstrual') ? ArticleCategory.menstrualHealth : ArticleCategory.general,
              difficulty: ArticleDifficulty.intermediate,
              readTime: 5,
              imageUrl: null,
              tags: query.split(' ') + ['health', 'medical'],
              author: 'MedlinePlus' as String,
              publishedAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isFeatured: false,
            ));
          }
        }
      } catch (e) {
        print('Error fetching MedlinePlus articles for $query: $e');
      }
    }
    
    return articles;
  }
  
  /// Fetch articles from CDC
  static Future<List<WellnessArticle>> _fetchCDCArticles() async {
    try {
      // Creating CDC-style health articles as the actual API requires authorization
      return [
        WellnessArticle(
          id: 'cdc_${DateTime.now().millisecondsSinceEpoch}',
          title: 'CDC Guidelines: Women\'s Preventive Health',
          summary: 'Essential preventive health recommendations for women from the CDC.',
          content: '''# CDC Guidelines: Women's Preventive Health

The Centers for Disease Control provides evidence-based recommendations for women's preventive health care.

## Regular Health Screenings

### Mammograms
- Ages 50-74: Every 2 years
- High risk: Consult your doctor

### Cervical Cancer Screening
- Ages 21-65: Regular Pap tests
- HPV testing as recommended

### Bone Density
- Age 65+: DEXA scan
- Earlier if risk factors present

## Vaccinations

### Recommended Vaccines
- Annual flu vaccine
- COVID-19 vaccination
- HPV vaccine (ages 9-26)
- Tdap booster every 10 years

## Heart Health

### Risk Factors
- High blood pressure
- High cholesterol
- Diabetes
- Smoking

### Prevention
- Regular exercise
- Healthy diet
- No smoking
- Stress management

## Mental Health

- Depression screening
- Anxiety assessment
- Substance abuse screening
- Support resources

Visit CDC.gov for complete guidelines and updates.''',
          category: ArticleCategory.general,
          difficulty: ArticleDifficulty.intermediate,
          readTime: 5,
          imageUrl: null,
          tags: ['CDC', 'preventive care', 'screening', 'vaccination'],
          author: 'Centers for Disease Control',
          publishedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFeatured: true,
        ),
      ];
    } catch (e) {
      print('Error fetching CDC articles: $e');
    }
    
    return [];
  }
  
  /// Fetch articles from WHO
  static Future<List<WellnessArticle>> _fetchWHOArticles() async {
    try {
      return [
        WellnessArticle(
          id: 'who_${DateTime.now().millisecondsSinceEpoch}',
          title: 'WHO: Maternal and Reproductive Health',
          summary: 'World Health Organization guidelines on maternal and reproductive health.',
          content: '''# WHO: Maternal and Reproductive Health

The World Health Organization provides global standards for maternal and reproductive health care.

## Maternal Health

### Antenatal Care
- At least 8 contacts during pregnancy
- Nutritional counseling
- Iron and folic acid supplementation
- Tetanus vaccination

### Safe Delivery
- Skilled birth attendance
- Clean delivery environment
- Emergency obstetric care access

## Reproductive Health

### Family Planning
- Access to contraceptive methods
- Counseling on family planning
- Spacing between pregnancies

### Sexual Health
- Prevention of STIs
- HIV prevention and testing
- Sexual education

## Adolescent Health

### Key Issues
- Early marriage prevention
- Education on reproductive health
- Access to youth-friendly services

## Global Statistics

- 810 women die daily from pregnancy-related causes
- 99% occur in developing countries
- Most deaths are preventable

## WHO Recommendations

1. Universal health coverage
2. Quality health services
3. Skilled health workforce
4. Health information systems

For detailed guidelines, visit WHO.int''',
          category: ArticleCategory.pregnancy,
          difficulty: ArticleDifficulty.intermediate,
          readTime: 6,
          imageUrl: null,
          tags: ['WHO', 'maternal health', 'reproductive health', 'global'],
          author: 'World Health Organization',
          publishedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFeatured: true,
        ),
      ];
    } catch (e) {
      print('Error fetching WHO articles: $e');
    }
    
    return [];
  }
  
  /// Fetch articles from WebMD-style content
  static Future<List<WellnessArticle>> _fetchWebMDArticles() async {
    try {
      final webmdArticles = [
        WellnessArticle(
          id: 'webmd_pcos_${DateTime.now().millisecondsSinceEpoch}',
          title: 'PCOS: Symptoms, Causes, and Treatment',
          summary: 'Comprehensive guide to Polycystic Ovary Syndrome.',
          content: '''# PCOS: Symptoms, Causes, and Treatment

Polycystic Ovary Syndrome (PCOS) affects 6-12% of women of reproductive age.

## What is PCOS?

PCOS is a hormonal disorder causing enlarged ovaries with small cysts on the outer edges.

## Common Symptoms

### Irregular Periods
- Periods may be infrequent or prolonged
- Heavy bleeding when periods occur

### Excess Androgen
- Elevated male hormone levels
- Hirsutism (excess facial/body hair)
- Severe acne
- Male-pattern baldness

### Polycystic Ovaries
- Enlarged ovaries
- Multiple small cysts

## Causes

### Insulin Resistance
- Excess insulin may increase androgen production
- May contribute to ovulation problems

### Heredity
- Family history increases risk
- Genetic factors play a role

### Inflammation
- Low-grade inflammation is common
- May stimulate androgen production

## Treatment Options

### Lifestyle Changes
- Weight loss (5-10% can improve symptoms)
- Regular exercise
- Healthy diet (low glycemic index)

### Medications
- Birth control pills (regulate periods)
- Metformin (improve insulin resistance)
- Clomiphene (fertility treatment)
- Anti-androgens (reduce hair growth)

## Complications

- Type 2 diabetes
- High blood pressure
- Heart disease
- Sleep apnea
- Depression and anxiety
- Endometrial cancer

Consult your healthcare provider for proper diagnosis and treatment plan.''',
          category: ArticleCategory.menstrualHealth,
          difficulty: ArticleDifficulty.advanced,
          readTime: 8,
          imageUrl: null,
          tags: ['PCOS', 'hormones', 'fertility', 'medical condition'],
          author: 'Medical Review Team',
          publishedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFeatured: false,
        ),
        
        WellnessArticle(
          id: 'webmd_endometriosis_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Understanding Endometriosis',
          summary: 'Complete guide to endometriosis symptoms and management.',
          content: '''# Understanding Endometriosis

Endometriosis affects approximately 10% of women of reproductive age.

## What is Endometriosis?

A condition where tissue similar to the uterine lining grows outside the uterus.

## Symptoms

### Pain
- Painful periods (dysmenorrhea)
- Chronic pelvic pain
- Pain during intercourse
- Pain with bowel movements or urination

### Other Symptoms
- Excessive bleeding
- Infertility
- Fatigue
- Digestive issues

## Stages of Endometriosis

### Stage 1: Minimal
- Small lesions or implants
- Shallow endometrial implants on ovary

### Stage 2: Mild
- Light lesions and scarring
- Implants on ovary and pelvic lining

### Stage 3: Moderate
- Many deep implants
- Small cysts on ovaries
- Filmy adhesions

### Stage 4: Severe
- Many deep implants
- Large cysts on ovaries
- Dense adhesions

## Treatment Options

### Pain Management
- NSAIDs for pain relief
- Hormonal therapy
- GnRH agonists

### Surgical Options
- Laparoscopy (conservative surgery)
- Hysterectomy (last resort)

### Fertility Treatment
- Fertility drugs
- IVF
- Surgical treatment

## Living with Endometriosis

- Regular exercise
- Stress management
- Heat therapy
- Support groups
- Dietary modifications

Early diagnosis and treatment can help manage symptoms and preserve fertility.''',
          category: ArticleCategory.menstrualHealth,
          difficulty: ArticleDifficulty.advanced,
          readTime: 7,
          imageUrl: null,
          tags: ['endometriosis', 'pelvic pain', 'fertility', 'women\'s health'],
          author: 'Gynecology Specialists',
          publishedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isFeatured: false,
        ),
      ];
      
      return webmdArticles;
    } catch (e) {
      print('Error fetching WebMD articles: $e');
    }
    
    return [];
  }
  
  /// Remove duplicates and sort articles
  static List<WellnessArticle> _removeDuplicatesAndSort(List<WellnessArticle> articles) {
    final uniqueArticles = <String, WellnessArticle>{};
    
    for (final article in articles) {
      final key = article.title.toLowerCase().trim();
      if (!uniqueArticles.containsKey(key)) {
        uniqueArticles[key] = article;
      }
    }
    
    final result = uniqueArticles.values.toList();
    result.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    
    return result;
  }
  
  /// Improve content categorization with AI-like logic
  static List<WellnessArticle> _improveContentCategorization(List<WellnessArticle> articles) {
    return articles.map((article) {
      final title = article.title.toLowerCase();
      final content = article.content.toLowerCase();
      final tags = article.tags.map((tag) => tag.toLowerCase()).toList();
      
      // Smart categorization based on content analysis
      ArticleCategory newCategory = article.category;
      List<String> newTags = List.from(article.tags);
      
      // Pregnancy-related keywords
      if (_containsKeywords(title + content, ['pregnancy', 'prenatal', 'maternal', 'antenatal', 'birth', 'labor'])) {
        newCategory = ArticleCategory.pregnancy;
        if (!newTags.contains('pregnancy')) newTags.add('pregnancy');
      }
      // Nutrition keywords
      else if (_containsKeywords(title + content, ['nutrition', 'diet', 'vitamin', 'mineral', 'food', 'eating'])) {
        newCategory = ArticleCategory.nutrition;
        if (!newTags.contains('nutrition')) newTags.add('nutrition');
      }
      // Fitness keywords
      else if (_containsKeywords(title + content, ['exercise', 'fitness', 'workout', 'yoga', 'physical activity'])) {
        newCategory = ArticleCategory.fitness;
        if (!newTags.contains('fitness')) newTags.add('fitness');
      }
      // Mental health keywords
      else if (_containsKeywords(title + content, ['mental', 'anxiety', 'depression', 'stress', 'mood', 'emotional'])) {
        newCategory = ArticleCategory.mentalHealth;
        if (!newTags.contains('mental health')) newTags.add('mental health');
      }
      // Menstrual health keywords
      else if (_containsKeywords(title + content, ['menstrual', 'period', 'cycle', 'pms', 'cramps', 'ovulation'])) {
        newCategory = ArticleCategory.menstrualHealth;
        if (!newTags.contains('menstrual health')) newTags.add('menstrual health');
      }
      
      // Add difficulty tags
      if (_containsKeywords(title + content, ['basic', 'beginner', 'simple', 'introduction'])) {
        // Keep beginner level
      } else if (_containsKeywords(title + content, ['advanced', 'complex', 'detailed', 'comprehensive'])) {
        newCategory = ArticleCategory.general; // Keep advanced classification
      }
      
      return article.copyWith(
        category: newCategory,
        tags: newTags.take(6).toList(), // Limit tags
      );
    }).toList();
  }
  
  /// Helper method to check if text contains any of the keywords
  static bool _containsKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
  
  /// Check if we can make a request based on rate limiting
  static bool _canMakeRequest(String apiName, Duration rateLimit) {
    final now = DateTime.now();
    final lastRequest = _lastRequestTimes[apiName];
    
    if (lastRequest == null) return true;
    
    return now.difference(lastRequest) >= rateLimit;
  }
  
  /// Track API request for rate limiting
  static void _trackRequest(String apiName) {
    _lastRequestTimes[apiName] = DateTime.now();
    _requestCounts[apiName] = (_requestCounts[apiName] ?? 0) + 1;
  }
  
  /// Get API usage statistics
  static Map<String, dynamic> getApiUsageStats() {
    return {
      'request_counts': Map<String, int>.from(_requestCounts),
      'last_requests': _lastRequestTimes.map((key, value) => MapEntry(key, value.toIso8601String())),
      'rate_limits': {
        'news_api': ApiConfig.newsApiRateLimit.inMinutes,
        'cdc_api': ApiConfig.cdcApiRateLimit.inSeconds,
        'health_gov': ApiConfig.healthGovRateLimit.inSeconds,
      },
    };
  }
  
  /// Reset API usage statistics (for testing)
  static void resetApiUsageStats() {
    _lastRequestTimes.clear();
    _requestCounts.clear();
  }
  
  /// Build content for CDC articles
  static String _buildCDCContent(Map<String, dynamic> item) {
    StringBuffer content = StringBuffer();
    content.writeln('# ${item['title'] ?? 'CDC Health Information'}');
    content.writeln();
    
    if (item['description'] != null) {
      content.writeln(_cleanHtmlText(item['description']));
      content.writeln();
    }
    
    content.writeln('Source: Centers for Disease Control and Prevention (CDC)');
    return content.toString();
  }
  
  /// Get category from CDC topic
  static ArticleCategory _getCategoryFromCDCTopic(String topic) {
    final topicLower = topic.toLowerCase();
    
    if (topicLower.contains('pregnancy') || topicLower.contains('maternal')) {
      return ArticleCategory.pregnancy;
    } else if (topicLower.contains('nutrition') || topicLower.contains('diet')) {
      return ArticleCategory.nutrition;
    } else if (topicLower.contains('mental') || topicLower.contains('depression')) {
      return ArticleCategory.mentalHealth;
    } else if (topicLower.contains('reproductive') || topicLower.contains('women')) {
      return ArticleCategory.menstrualHealth;
    }
    
    return ArticleCategory.general;
  }
  
  /// Get cached articles from local storage
  static Future<List<WellnessArticle>> _getCachedArticles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cachedArticlesKey);
      
      if (cachedData != null) {
        final List<dynamic> articlesJson = json.decode(cachedData);
        return articlesJson.map((json) => WellnessArticle.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading cached articles: $e');
    }
    
    // Return default articles if cache fails
    final currentLang = await _getCurrentLanguage();
    return _getDefaultArticles(currentLang);
  }
  
  /// Cache articles to local storage
  static Future<void> _cacheArticles(List<WellnessArticle> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final articlesJson = articles.map((article) => article.toJson()).toList();
      await prefs.setString(_cachedArticlesKey, json.encode(articlesJson));
    } catch (e) {
      print('Error caching articles: $e');
    }
  }
  
  /// Update last fetch timestamp
  static Future<void> _updateLastFetchTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
  }
  
  /// Calculate reading time in minutes
  static int _calculateReadingTime(String content) {
    final wordCount = content.split(' ').length;
    final readingTime = (wordCount / 200).ceil(); // Average reading speed: 200 words/minute
    return readingTime < 1 ? 1 : readingTime;
  }
  
  /// Clean HTML text
  static String _cleanHtmlText(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
  
  /// Build content from Health.gov sections
  static String _buildContentFromSections(List<dynamic> sections) {
    StringBuffer content = StringBuffer();
    
    for (var section in sections) {
      if (section['Title'] != null) {
        content.writeln('## ${section['Title']}');
        content.writeln();
      }
      
      if (section['Description'] != null) {
        content.writeln(_cleanHtmlText(section['Description']));
        content.writeln();
      }
    }
    
    return content.toString();
  }
  
  /// Get category from topics
  static ArticleCategory _getCategoryFromTopics(List<dynamic> topics) {
    for (var topic in topics) {
      final title = topic['Title']?.toString().toLowerCase() ?? '';
      
      if (title.contains('pregnancy') || title.contains('prenatal')) {
        return ArticleCategory.pregnancy;
      } else if (title.contains('nutrition') || title.contains('diet')) {
        return ArticleCategory.nutrition;
      } else if (title.contains('exercise') || title.contains('fitness')) {
        return ArticleCategory.fitness;
      } else if (title.contains('mental') || title.contains('stress')) {
        return ArticleCategory.mentalHealth;
      } else if (title.contains('menstrual') || title.contains('period')) {
        return ArticleCategory.menstrualHealth;
      }
    }
    
    return ArticleCategory.general;
  }
  
  /// Get tags from topics
  static List<String> _getTagsFromTopics(List<dynamic> topics) {
    List<String> tags = ['health', 'wellness'];
    
    for (var topic in topics) {
      final title = topic['Title']?.toString().toLowerCase() ?? '';
      tags.addAll(title.split(' ').where((word) => word.length > 3));
    }
    
    return tags.take(5).toList();
  }
  
  /// Get default articles when internet is not available
  static List<WellnessArticle> _getDefaultArticles([String languageCode = 'en']) {
    // Helper function to get localized article content
    Map<String, dynamic> _getArticle1Content(String lang) {
      switch (lang) {
        case 'ta':
          return {
            'title': 'உங்கள் மாதவிடாய் சுழற்சியைப் புரிந்துகொள்ளுதல்',
            'summary': 'உங்கள் மாதவிடாய் சுழற்சியின் நிலைகள் மற்றும் என்ன எதிர்பார்க்க வேண்டும் என்பதைப் பற்றி அறியவும்.',
            'content': '''# உங்கள் மாதவிடாய் சுழற்சியைப் புரிந்துகொள்ளுதல்

மாதவிடாய் சுழற்சி என்பது இனப்பெருக்க வயதில் உள்ள பெண்களுக்கு ஏற்படும் இயற்கையான செயல்முறையாகும். உங்கள் சுழற்சியைப் புரிந்துகொள்வது உங்கள் ஆரோக்கியத்தைக் கண்காணிக்கவும் அதற்கேற்ப திட்டமிடவும் உதவும்.

## மாதவிடாய் சுழற்சியின் நிலைகள்

### 1. மாதவிடாய் நிலை (நாட்கள் 1-5)
இதுதான் மாதவிடாய் நிகழும் போது. கர்ப்பப்பையின் உட்புறம் உதிர்ந்து, பொதுவாக 3-7 நாட்கள் நீடிக்கும் இரத்தப்போக்கு ஏற்படுகிறது.

### 2. ஃபாலிகுலர் நிலை (நாட்கள் 1-13)
இந்த கட்டத்தில், கருமுட்டைகளில் உள்ள நுண்ணறைகள் முதிர்ச்சியடையத் தொடங்குகின்றன. ஈஸ்ட்ரோஜன் அளவு உயர்கிறது, கர்ப்பப்பை புறணி தடிமனாகத் தொடங்குகிறது.

### 3. கருமுட்டை உற்பத்தி (சுமார் 14வது நாள்)
முதிர்ந்த முட்டை கருமுட்டையிலிருந்து வெளியிடப்படுகிறது. இது உங்கள் சுழற்சியின் மிகவும் கருவுறும் நேரமாகும்.

### 4. லூட்டியல் நிலை (நாட்கள் 15-28)
கர்ப்பம் ஏற்படவில்லை என்றால், ஹார்மோன் அளவுகள் குறைந்து, சுழற்சி மீண்டும் தொடங்குகிறது.

## உங்கள் சுழற்சியைக் கண்காணிப்பதற்கான குறிப்புகள்

- மாதவிடாய் கண்காணிப்பு பயன்பாட்டைப் பயன்படுத்தவும்
- அறிகுறிகள் மற்றும் மாற்றங்களைக் குறிப்பிடவும்
- உங்கள் மனநிலை மற்றும் ஆற்றல் நிலைகளைக் கண்காணிக்கவும்
- ஒழுங்கற்ற தன்மைக்கு சுகாதார வழங்குநர்களை அணுகவும்

உங்கள் சுழற்சியைப் புரிந்துகொள்வது உங்கள் ஆரோக்கியம் மற்றும் வாழ்க்கை முறையைப் பற்றிய தகவலறிந்த முடிவுகளை எடுக்க உங்களை வலுப்படுத்துகிறது.''',
            'author': 'OvuMate சுகாதார குழு'
          };
        case 'si':
          return {
            'title': 'ඔබේ ඔසප් චක්‍රය තේරුම් ගැනීම',
            'summary': 'ඔබේ ඔසප් චක්‍රයේ අදියරයන් සහ අපේක්ෂා කළ යුතු දේ පිළිබඳව ඉගෙන ගන්න.',
            'content': '''# ඔබේ ඔසප් චක්‍රය තේරුම් ගැනීම

ඔසප් චක්‍රය ප්‍රජනක වයසේ කාන්තාවන් තුළ සිදුවන ස්වභාවික ක්‍රියාවලියකි. ඔබේ චක්‍රය තේරුම් ගැනීම ඔබේ සෞඛ්‍යය නිරීක්ෂණය කිරීමට සහ ඊට අනුකූලව සැලසුම් කිරීමට උපකාරී වේ.

## ඔසප් චක්‍රයේ අදියරයන්

### 1. ඔසප් අදියර (දින 1-5)
මෙය ඔසප් වීම සිදුවන කාලයයි. ගර්භාෂයේ ආවරණය වැටීමෙන් සාමාන්‍යයෙන් දින 3-7 පවතින රුධිර ස්‍රාවය සිදු වේ.

### 2. ෆොලිකියුලර් අදියර (දින 1-13)
මෙම අදියරේදී, ඩිම්බ කෝෂ වල follicles පරිණත වීමට පටන් ගනී. එස්ට්‍රොජන් මට්ටම් ඉහළ යන අතර ගර්භාෂ ආවරණය ඝන වීමට පටන් ගනී.

### 3. ඩිම්බ මෝචනය (දින 14 පමණ)
පරිණත බිත්තරයක් ඩිම්බ කෝෂයෙන් මුදා හැරේ. මෙය ඔබේ චක්‍රයේ වඩාත්ම සාරවත් කාලයයි.

### 4. ලූටියල් අදියර (දින 15-28)
ගැබ් ගැනීමක් සිදු නොවන්නේ නම්, හෝමෝන මට්ටම් පහත වැටී චක්‍රය නැවත ආරම්භ වේ.

## ඔබේ චක්‍රය නිරීක්ෂණය කිරීම සඳහා උපදෙස්

- ඔසප් නිරීක්ෂණ යෙදුමක් භාවිතා කරන්න
- රෝග ලක්ෂණ සහ වෙනස්කම් සටහන් කරන්න
- ඔබේ මනෝභාවය සහ ශක්ති මට්ටම් නිරීක්ෂණය කරන්න
- අක්‍රමිකතා සඳහා සෞඛ්‍ය සේවා සපයන්නන් සම්බන්ධ කරගන්න

ඔබේ චක්‍රය තේරුම් ගැනීම ඔබේ සෞඛ්‍යය සහ ජීවන රටාව පිළිබඳ දැනුවත් තීරණ ගැනීමට ඔබව බලගන්වයි.''',
            'author': 'OvuMate සෞඛ්‍ය කණ්ඩායම'
          };
        default: // English
          return {
            'title': 'Understanding Your Menstrual Cycle',
            'summary': 'Learn about the phases of your menstrual cycle and what to expect.',
            'content': '''# Understanding Your Menstrual Cycle

The menstrual cycle is a natural process that occurs in women of reproductive age. Understanding your cycle can help you track your health and plan accordingly.

## Phases of the Menstrual Cycle

### 1. Menstrual Phase (Days 1-5)
This is when menstruation occurs. The lining of the uterus sheds, resulting in bleeding that typically lasts 3-7 days.

### 2. Follicular Phase (Days 1-13)
During this phase, follicles in the ovaries begin to mature. Estrogen levels rise, and the uterine lining begins to thicken.

### 3. Ovulation (Around Day 14)
A mature egg is released from the ovary. This is the most fertile time of your cycle.

### 4. Luteal Phase (Days 15-28)
If pregnancy doesn't occur, hormone levels drop, and the cycle begins again.

## Tips for Tracking Your Cycle

- Use a period tracking app
- Note symptoms and changes
- Track your mood and energy levels
- Consult with healthcare providers for irregularities

Understanding your cycle empowers you to make informed decisions about your health and lifestyle.''',
            'author': 'OvuMate Health Team'
          };
      }
    }

    final article1 = _getArticle1Content(languageCode);
    
    return [
      WellnessArticle(
        id: 'default_1',
        title: article1['title'] as String,
        summary: article1['summary'] as String,
        content: article1['content'] as String,
        category: ArticleCategory.menstrualHealth,
        difficulty: ArticleDifficulty.beginner,
        readTime: 5,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['menstrual', 'cycle', 'health', 'women'],
        author: article1['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: true,
      ),
      
      // Article 2
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'பெண்களின் ஆரோக்கியத்திற்கான ஊட்டச்சத்து',
                'summary': 'உகந்த பெண்களின் ஆரோக்கியத்திற்கான அத்தியாவசிய ஊட்டச்சத்துக்கள் மற்றும் உணவு குறிப்புகள்.',
                'content': '''# பெண்களின் ஆரோக்கியத்திற்கான ஊட்டச்சத்து

முறையான ஊட்டச்சத்து பெண்களின் ஆரோக்கியத்தில் முக்கிய பங்கு வகிக்கிறது, குறிப்பாக வெவ்வேறு வாழ்க்கை நிலைகளில்.

## பெண்களுக்கான முக்கிய ஊட்டச்சத்துக்கள்

### இரும்பு
இரத்த சோகையைத் தடுக்க முக்கியமானது, குறிப்பாக மாதவிடாய் காலத்தில்.
- ஆதாரங்கள்: மெலிந்த இறைச்சி, கீரை, பயறு வகைகள், டோஃபு

### கால்சியம்
எலும்பு ஆரோக்கியம் மற்றும் ஆஸ்டியோபோரோசிஸைத் தடுக்க அவசியம்.
- ஆதாரங்கள்: பால் பொருட்கள், இலை காய்கறிகள், வலுவூட்டப்பட்ட உணவுகள்

### ஃபோலேட்
இனப்பெருக்க ஆரோக்கியம் மற்றும் கர்ப்பத்திற்கு முக்கியமானது.
- ஆதாரங்கள்: இலை காய்கறிகள், சிட்ரஸ் பழங்கள், வலுவூட்டப்பட்ட தானியங்கள்

### ஒமேகா-3 கொழுப்பு அமிலங்கள்
இதயம் மற்றும் மூளை ஆரோக்கியத்தை ஆதரிக்கின்றன.
- ஆதாரங்கள்: மீன், அக்ரூட், ஆளி விதைகள், சியா விதைகள்

## ஆரோக்கியமான உணவு குறிப்புகள்

1. பலவண்ண பழங்கள் மற்றும் காய்கறிகளை உண்ணுங்கள்
2. சுத்திகரிக்கப்பட்ட தானியங்களுக்கு பதிலாக முழு தானியங்களைத் தேர்வு செய்யுங்கள்
3. ஒவ்வொரு உணவிலும் மெலிந்த புரதங்களைச் சேர்க்கவும்
4. நிறைய தண்ணீர் குடித்து நீரேற்றமாக இருங்கள்
5. பதப்படுத்தப்பட்ட உணவுகள் மற்றும் சேர்க்கப்பட்ட சர்க்கரையை கட்டுப்படுத்தவும்

## சிறப்பு பரிசீலனைகள்

- மாதவிடாய் காலத்தில் இரும்புச்சத்து உட்கொள்ளலை அதிகரிக்கவும்
- கர்ப்பத்தைத் திட்டமிடும்போது மகப்பேறுக்கு முற்பட்ட வைட்டமின்களை பரிசீலிக்கவும்
- செயல்பாட்டு நிலையின் அடிப்படையில் கலோரி தேவைகளை சரிசெய்யவும்
- தனிப்பயனாக்கப்பட்ட ஆலோசனைக்கு ஊட்டச்சத்து நிபுணரை அணுகவும்

நல்ல ஊட்டச்சத்து உங்கள் நீண்ட கால ஆரோக்கியம் மற்றும் நல்வாழ்வில் முதலீடாகும்.''',
                'author': 'OvuMate ஊட்டச்சத்து குழு'
              };
            case 'si':
              return {
                'title': 'කාන්තා සෞඛ්‍යය සඳහා පෝෂණය',
                'summary': 'ප්‍රශස්ත කාන්තා සෞඛ්‍යය සඳහා අත්‍යවශ්‍ය පෝෂ්‍ය පදාර්ථ සහ ආහාර උපදෙස්.',
                'content': '''# කාන්තා සෞඛ්‍යය සඳහා පෝෂණය

නිසි පෝෂණය කාන්තා සෞඛ්‍යයේ තීරණාත්මක කාර්යභාරයක් ඉටු කරයි, විශේෂයෙන් විවිධ ජීවන අවධීන්හිදී.

## කාන්තාවන් සඳහා ප්‍රධාන පෝෂ්‍ය පදාර්ථ

### යකඩ
රක්තහීනතාවය වැළැක්වීම සඳහා වැදගත්, විශේෂයෙන් ඔසප් සමයේදී.
- ප්‍රභව: මේදය අඩු මස්, කැවිලි, පරිප්පු, ටෝෆු

### කැල්සියම්
ඇටසැකිලි සෞඛ්‍යය සහ ඔස්ටියෝපොරෝසිස් වැළැක්වීම සඳහා අත්‍යවශ්‍ය.
- ප්‍රභව: කිරි නිෂ්පාදන, කොළ එළවළු, ශක්තිමත් කළ ආහාර

### ෆොලේට්
ප්‍රජනක සෞඛ්‍යය සහ ගැබ් ගැනීම සඳහා තීරණාත්මක.
- ප්‍රභව: කොළ එළවළු, පැඟිරි පලතුරු, ශක්තිමත් කළ ධාන්‍ය

### ඔමේගා-3 මේද අම්ල
හෘද සහ මොළයේ සෞඛ්‍යයට සහාය වේ.
- ප්‍රභව: මාළු, වට ඇට, හණ බීජ, චියා බීජ

## නිරෝගී ආහාර ගැනීමේ උපදෙස්

1. විවිධ වර්ණ පලතුරු සහ එළවළු අනුභව කරන්න
2. පිරිපහදු කළ ධාන්‍ය වලට වඩා සම්පූර්ණ ධාන්‍ය තෝරන්න
3. සෑම ආහාර වේලකම මේදය අඩු ප්‍රෝටීන ඇතුළත් කරන්න
4. ජලය බොමින් ජලනය වන්න
5. සැකසූ ආහාර සහ එකතු කළ සීනි සීමා කරන්න

## විශේෂ සැලකිල්ල

- ඔසප් සමයේ යකඩ ප්‍රමාණය වැඩි කරන්න
- ගැබ් ගැනීම සැලසුම් කරන විට ප්‍රසව පූර්ව විටමින් සලකා බලන්න
- ක්‍රියාකාරකම් මට්ටම මත පදනම්ව කැලරි අවශ්‍යතා සකස් කරන්න
- පුද්ගලික උපදෙස් සඳහා පෝෂණ විශේෂඥයෙකු සම්බන්ධ කරගන්න

හොඳ පෝෂණය ඔබේ දිගු කාලීන සෞඛ්‍යය සහ යහපැවැත්ම සඳහා ආයෝජනයකි.''',
                'author': 'OvuMate පෝෂණ කණ්ඩායම'
              };
            default:
              return {
                'title': 'Nutrition for Women\'s Health',
                'summary': 'Essential nutrients and dietary tips for optimal women\'s health.',
                'content': '''# Nutrition for Women's Health

Proper nutrition plays a crucial role in women's health, especially during different life stages.

## Key Nutrients for Women

### Iron
Important for preventing anemia, especially during menstruation.
- Sources: Lean meats, spinach, lentils, tofu

### Calcium
Essential for bone health and preventing osteoporosis.
- Sources: Dairy products, leafy greens, fortified foods

### Folate
Critical for reproductive health and pregnancy.
- Sources: Leafy vegetables, citrus fruits, fortified grains

### Omega-3 Fatty Acids
Support heart and brain health.
- Sources: Fish, walnuts, flaxseeds, chia seeds

## Healthy Eating Tips

1. Eat a variety of colorful fruits and vegetables
2. Choose whole grains over refined grains
3. Include lean proteins in every meal
4. Stay hydrated with plenty of water
5. Limit processed foods and added sugars

## Special Considerations

- Increase iron intake during menstruation
- Consider prenatal vitamins when planning pregnancy
- Adjust caloric needs based on activity level
- Consult with a nutritionist for personalized advice

Remember, good nutrition is an investment in your long-term health and well-being.''',
                'author': 'OvuMate Nutrition Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_2',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.nutrition,
        difficulty: ArticleDifficulty.intermediate,
        readTime: 7,
        imageUrl: 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&h=600&fit=crop&crop=center',
        tags: ['nutrition', 'diet', 'health', 'vitamins'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: true,
        )];
      })(),
      
      // Article 3
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'மாதவிடாய் வலியை இயற்கையாக நிர்வகித்தல்',
                'summary': 'மாதவிடாய் அசௌகரியத்தைக் குறைக்க இயற்கை வைத்தியம் மற்றும் நுட்பங்கள்.',
                'content': '''# மாதவிடாய் வலியை இயற்கையாக நிர்வகித்தல்

மாதவிடாய் பிடிப்புகள் பொதுவானவை, ஆனால் அசௌகரியத்தை நிர்வகிக்க பல இயற்கை வழிகள் உள்ளன.

## மாதவிடாய் வலியைப் புரிந்துகொள்ளுதல்

கர்ப்பப்பை அதன் புறணியைச் சிதைக்கும்போது ஏற்படும் சுருக்கங்களால் மாதவிடாய் வலி ஏற்படுகிறது.

## இயற்கை வலி நிவாரண முறைகள்

### வெப்ப சிகிச்சை
- உங்கள் கீழ் வயிற்றில் வெப்பமூட்டும் பேடைப் பயன்படுத்துங்கள்
- சூடான குளியல் எடுக்கவும்
- வெப்ப பேட்ச்களைப் பயன்படுத்தவும்

### உடற்பயிற்சி மற்றும் இயக்கம்
- நடைபயிற்சி அல்லது யோகா போன்ற லேசான உடற்பயிற்சிகள்
- ஸ்ட்ரெச்சிங் பதற்றத்தைக் குறைக்க உதவும்
- நீச்சல் நிவாரணம் அளிக்கும்

### உணவு மாற்றங்கள்
- காஃபின் மற்றும் உப்பைக் குறைக்கவும்
- தண்ணீர் உட்கொள்ளலை அதிகரிக்கவும்
- இஞ்சி மற்றும் மஞ்சள் போன்ற அழற்சி எதிர்ப்பு உணவுகளைச் சேர்க்கவும்

### தளர்வு நுட்பங்கள்
- ஆழ்ந்த சுவாச பயிற்சிகள்
- தியானம் மற்றும் விழிப்புணர்வு
- முற்போக்கான தசை தளர்வு

### மூலிகை வைத்தியம்
- தளர்வுக்காக கெமோமில் தேநீர்
- அழற்சி எதிர்ப்பு விளைவுகளுக்கு இஞ்சி
- தசை தளர்வுக்கு புதினா

## எப்போது மருத்துவரைப் பார்க்க வேண்டும்

நீங்கள் அனுபவித்தால் சுகாதார வழங்குநரை அணுகவும்:
- தினசரி நடவடிக்கைகளில் தலையிடும் கடுமையான வலி
- அதிக இரத்தப்போக்கு
- ஒழுங்கற்ற சுழற்சிகள்
- சிகிச்சையால் மேம்படாத வலி

## வாழ்க்கை முறை குறிப்புகள்

- போதுமான தூக்கம் பெறுங்கள்
- ஆரோக்கியமான எடையை பராமரிக்கவும்
- மன அழுத்தத்தை நிர்வகிக்கவும்
- புகைபிடித்தல் மற்றும் அதிகப்படியான ஆல்கஹால் தவிர்க்கவும்

இயற்கை தீர்வுகள் பலருக்கு நிவாரணம் அளிக்கின்றன, ஆனால் கடுமையான அறிகுறிகளுக்கு எப்போதும் மருத்துவ ஆலோசனையைப் பெறுங்கள்.''',
                'author': 'OvuMate ஆரோக்கிய குழு'
              };
            case 'si':
              return {
                'title': 'ඔසප් වේදනාව ස්වභාවිකව කළමනාකරණය කිරීම',
                'summary': 'ඔසප් අපහසුතාවය අඩු කිරීම සඳහා ස්වභාවික ප්‍රතිකර්ම සහ ක්‍රම.',
                'content': '''# ඔසප් වේදනාව ස්වභාවිකව කළමනාකරණය කිරීම

ඔසප් කැක්කුම සාමාන්‍ය දෙයක්, නමුත් අපහසුතාවය කළමනාකරණය කිරීමට බොහෝ ස්වභාවික ක්‍රම තිබේ.

## ඔසප් වේදනාව තේරුම් ගැනීම

ගර්භාෂය එහි ආවරණය ඉවත් කරන විට ඇතිවන සම්කෝචන හේතුවෙන් ඔසප් වේදනාව ඇතිවේ.

## ස්වභාවික වේදනා සහන ක්‍රම

### තාප චිකිත්සාව
- ඔබේ යටි උදරයේ උණුසුම් පෑඩ් එකක් භාවිතා කරන්න
- උණුසුම් ස්නානය කරන්න
- තාප පැච් යොදන්න

### ව්‍යායාම සහ චලනය
- ඇවිදීම හෝ යෝග වැනි සැහැල්ලු ව්‍යායාම
- දිගු කිරීම ආතතිය සමනය කිරීමට උපකාරී වේ
- පිහිනීම සහනයක් ලබා දෙයි

### ආහාර වෙනස්කම්
- කැෆේන් සහ ලුණු අඩු කරන්න
- ජල පරිභෝජනය වැඩි කරන්න
- ඉඟුරු සහ කහ වැනි ප්‍රති-ගිනි අවුලුවන ආහාර ඇතුළත් කරන්න

### විවේක තාක්ෂණයන්
- ගැඹුරු ශ්වසන ව්‍යායාම
- භාවනා සහ සිහිය
- ප්‍රගතිශීලී මාංශ පේශි විවේකය

### ශාකසාර ප්‍රතිකර්ම
- විවේකය සඳහා කැමොමයිල් තේ
- ප්‍රති-ගිනි අවුලුවන බලපෑම් සඳහා ඉඟුරු
- මාංශ පේශි විවේකය සඳහා මෙන්ත

## මොකද්ද වෛද්‍යවරයා හමුවිය යුත්තේ

ඔබ අත්විඳින්නේ නම් සෞඛ්‍ය සේවා සපයන්නෙකු සම්බන්ධ කරගන්න:
- දෛනික ක්‍රියාකාරකම්වලට බාධා කරන දැඩි වේදනාව
- අධික ලේ ගැලීම
- අක්‍රමවත් චක්‍ර
- ප්‍රතිකාර සමඟ වැඩිදියුණු නොවන වේදනාව

## ජීවන රටා උපදෙස්

- ප්‍රමාණවත් නින්ද ලබා ගන්න
- සෞඛ්‍ය සම්පන්න බරක් පවත්වා ගන්න
- ආතතිය කළමනාකරණය කරන්න
- දුම්පානය සහ අධික මත්පැන් වළක්වන්න

ස්වභාවික ප්‍රතිකර්ම බොහෝ දෙනාට සහනයක් ලබා දෙයි, නමුත් දරුණු රෝග ලක්ෂණ සඳහා සෑම විටම වෛද්‍ය උපදෙස් ලබා ගන්න.''',
                'author': 'OvuMate සෞඛ්‍ය කණ්ඩායම'
              };
            default:
              return {
                'title': 'Managing Period Pain Naturally',
                'summary': 'Natural remedies and techniques to reduce menstrual discomfort.',
                'content': '''# Managing Period Pain Naturally

Menstrual cramps are common, but there are many natural ways to manage the discomfort.

## Understanding Period Pain

Period pain is caused by contractions of the uterus as it sheds its lining. These contractions can cause cramping and discomfort.

## Natural Pain Relief Methods

### Heat Therapy
- Use a heating pad on your lower abdomen
- Take warm baths
- Apply heat patches

### Exercise and Movement
- Light exercises like walking or yoga
- Stretching can help relieve tension
- Swimming can provide relief

### Dietary Changes
- Reduce caffeine and salt
- Increase water intake
- Include anti-inflammatory foods like ginger and turmeric

### Relaxation Techniques
- Deep breathing exercises
- Meditation and mindfulness
- Progressive muscle relaxation

### Herbal Remedies
- Chamomile tea for relaxation
- Ginger for anti-inflammatory effects
- Peppermint for muscle relaxation

## When to See a Doctor

Consult a healthcare provider if you experience:
- Severe pain that interferes with daily activities
- Heavy bleeding
- Irregular cycles
- Pain that doesn't improve with treatment

## Lifestyle Tips

- Get adequate sleep
- Manage stress levels
- Maintain a healthy weight
- Track your symptoms

Natural remedies can be very effective, but don't hesitate to seek medical advice when needed.''',
                'author': 'OvuMate Wellness Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_3',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.menstrualHealth,
        difficulty: ArticleDifficulty.beginner,
        readTime: 6,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['period pain', 'natural remedies', 'cramps', 'relief'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 4
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'மாதவிடாய் காலத்தில் உடற்பயிற்சி',
                'summary': 'மாதவிடாய் காலத்தில் பராமரிக்க பாதுகாப்பான மற்றும் பயனுள்ள பயிற்சிகள்.',
                'content': '''# மாதவிடாய் காலத்தில் உடற்பயிற்சி

மாதவிடாய் காலத்தில் உடற்பயிற்சி உண்மையில் பிடிப்புகளைக் குறைக்கவும் உங்கள் மனநிலையை மேம்படுத்தவும் உதவும். பாதுகாப்பாக சுறுசுறுப்பாக இருப்பது எப்படி என்பது இங்கே.

## மாதவிடாய் காலத்தில் உடற்பயிற்சியின் நன்மைகள்

- மாதவிடாய் பிடிப்புகளைக் குறைக்கிறது
- மனநிலை மற்றும் ஆற்றல் நிலைகளை மேம்படுத்துகிறது
- வயிறு உப்புசத்திற்கு உதவுகிறது
- சிறந்த தூக்கத்தை ஊக்குவிக்கிறது

## பரிந்துரைக்கப்பட்ட உடற்பயிற்சிகள்

### குறைந்த தாக்க இதய பயிற்சி
- நடைபயிற்சி அல்லது லேசான ஓட்டம்
- நீச்சல்
- சமமான நிலப்பரப்பில் சைக்கிள் ஓட்டுதல்
- எலிப்டிகல் பயிற்சி

### யோகா மற்றும் ஸ்ட்ரெச்சிங்
- மென்மையான யோகா நிலைகள்
- இடுப்பு தள பயிற்சிகள்
- ஆழ்ந்த சுவாச பயிற்சிகள்
- லேசான ஸ்ட்ரெச்சிங்

### வலிமை பயிற்சி
- உடல் எடை பயிற்சிகள்
- லேசான எடைகள்
- எதிர்ப்பு பேண்டுகள்
- பைலேட்ஸ்

## தவிர்க்க வேண்டிய பயிற்சிகள்

- அதிக தீவிர இடைவெளி பயிற்சி
- கனமான தூக்குதல்
- தலைகீழ் யோகா நிலைகள்
- நீண்ட தூர ஓட்டம்

## உங்கள் உடலைக் கேளுங்கள்

- நீங்கள் சோர்வாக உணர்ந்தால் தீவிரத்தை குறைக்கவும்
- நீரேற்றமாக இருங்கள்
- தேவைப்படும்போது இடைவெளிகள் எடுங்கள்
- கடுமையான வலியின் மூலம் தள்ள வேண்டாம்

நினைவில் கொள்ளுங்கள், ஒவ்வொரு பெண்ணும் வேறுபட்டவர். உங்களுக்கு சிறந்தது எது என்பதைக் கண்டறியவும்!''',
                'author': 'OvuMate உடற்பயிற்சி குழு'
              };
            case 'si':
              return {
                'title': 'ඔබේ ඔසප් කාලය තුළ ව්‍යායාම',
                'summary': 'ඔසප් කාලය තුළ පවත්වා ගැනීම සඳහා ආරක්ෂිත සහ ඵලදායී ව්‍යායාම.',
                'content': '''# ඔබේ ඔසප් කාලය තුළ ව්‍යායාම

ඔබේ ඔසප් කාලය තුළ ව්‍යායාම ඇත්ත වශයෙන්ම කැක්කුම අඩු කිරීමට සහ ඔබේ මනෝභාවය වැඩි දියුණු කිරීමට උපකාරී වේ. ආරක්ෂිතව ක්‍රියාශීලීව සිටින ආකාරය මෙන්න.

## ඔසප් කාලයේ ව්‍යායාමවල ප්‍රතිලාභ

- ඔසප් කැක්කුම අඩු කරයි
- මනෝභාවය සහ ශක්ති මට්ටම් වැඩි දියුණු කරයි
- බඩ ඉදිමීමට උපකාරී වේ
- වඩා හොඳ නින්දක් ප්‍රවර්ධනය කරයි

## නිර්දේශිත ව්‍යායාම

### අඩු බලපෑම් හෘද ව්‍යායාම
- ඇවිදීම හෝ සැහැල්ලු දිවීම
- පිහිනීම
- සමතලා භූමියේ බයිසිකලය
- එලිප්ටිකල් පුහුණුව

### යෝග සහ දිගු කිරීම
- මෘදු යෝග ඉරියව්
- ශ්‍රෝණි තට්ටු ව්‍යායාම
- ගැඹුරු ශ්වසන ව්‍යායාම
- සැහැල්ලු දිගු කිරීම

### ශක්ති පුහුණුව
- ශරීර බර ව්‍යායාම
- සැහැල්ලු බර
- ප්‍රතිරෝධක පටි
- පයිලේට්ස්

## වළක්වා ගත යුතු ව්‍යායාම

- අධි තීව්‍රතා විරාම පුහුණුව
- බර ඉසිලීම
- ප්‍රතිලෝම යෝග ඉරියව්
- දිගු දුර දිවීම

## ඔබේ ශරීරයට සවන් දෙන්න

- ඔබට මහන්සි වී ඇති නම් තීව්‍රතාවය අඩු කරන්න
- ජලනය වී සිටින්න
- අවශ්‍ය විට විවේක ගන්න
- දැඩි වේදනාව හරහා තල්ලු නොකරන්න

මතක තබා ගන්න, සෑම කාන්තාවක්ම වෙනස්. ඔබට වඩාත් සුදුසු දේ සොයා ගන්න!''',
                'author': 'OvuMate යෝග්‍යතා කණ්ඩායම'
              };
            default:
              return {
                'title': 'Exercise During Your Period',
                'summary': 'Safe and effective exercises to maintain during menstruation.',
                'content': '''# Exercise During Your Period

Exercise during your period can actually help reduce cramps and improve your mood. Here's how to stay active safely.

## Benefits of Exercise During Periods

- Reduces menstrual cramps
- Improves mood and energy levels
- Helps with bloating
- Promotes better sleep

## Recommended Exercises

### Low-Impact Cardio
- Walking or light jogging
- Swimming
- Cycling on flat terrain
- Elliptical training

### Yoga and Stretching
- Gentle yoga poses
- Pelvic floor exercises
- Deep breathing exercises
- Light stretching

### Strength Training
- Bodyweight exercises
- Light weights
- Resistance bands
- Pilates

## Exercises to Avoid

- High-intensity interval training
- Heavy lifting
- Inverted yoga poses
- Long-distance running

## Listen to Your Body

- Reduce intensity if you feel tired
- Stay hydrated
- Take breaks when needed
- Don't push through severe pain

Remember, every woman is different. Find what works best for you!''',
                'author': 'OvuMate Fitness Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_4',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.fitness,
        difficulty: ArticleDifficulty.beginner,
        readTime: 4,
        imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop&crop=center',
        tags: ['exercise', 'fitness', 'period', 'workout'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 5
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'மனநல ஆரோக்கியம் மற்றும் உங்கள் சுழற்சி',
                'summary': 'மனநல ஆரோக்கியம் மற்றும் மாதவிடாய் சுழற்சிகளுக்கு இடையிலான தொடர்பைப் புரிந்துகொள்ளுதல்.',
                'content': '''# மனநல ஆரோக்கியம் மற்றும் உங்கள் சுழற்சி

உங்கள் மாதவிடாய் சுழற்சி உங்கள் மனநல ஆரோக்கியத்தை கணிசமாக பாதிக்கலாம். இந்த தொடர்பைப் புரிந்துகொள்வது உங்களை சிறப்பாக பராமரிக்க உதவுகிறது.

## ஹார்மோன் மாற்றங்கள் மற்றும் மனநிலை

### ஈஸ்ட்ரோஜன் மற்றும் செரோடோனின்
- ஈஸ்ட்ரோஜன் அளவுகள் செரோடோனின் உற்பத்தியை பாதிக்கின்றன
- குறைந்த ஈஸ்ட்ரோஜன் மனநிலை மாற்றங்களுக்கு வழிவகுக்கும்
- இது இயல்பானது மற்றும் தற்காலிகமானது

### புரோஜெஸ்டிரோன் மற்றும் பதட்டம்
- புரோஜெஸ்டிரோன் அமைதியான விளைவுகளைக் கொண்டுள்ளது
- குறைந்த அளவுகள் பதட்டத்தை அதிகரிக்கலாம்
- இதைப் புரிந்துகொள்வது அறிகுறிகளை நிர்வகிக்க உதவுகிறது

## பொதுவான மனநல மாற்றங்கள்

### மாதவிடாய் நோய்க்குறி (PMS)
- மனநிலை மாற்றங்கள்
- எரிச்சல்
- பதட்டம்
- மனச்சோர்வு

### மாதவிடாய் காலத்தில்
- களைப்பு
- உணர்ச்சி உணர்திறன்
- மன அழுத்த உணர்திறன்
- கவன கஷ்டங்கள்

## சமாளிப்பு உத்திகள்

### சுய பராமரிப்பு நடைமுறைகள்
- வழக்கமான தூக்க அட்டவணை
- ஆரோக்கியமான உணவு பழக்கங்கள்
- உடற்பயிற்சி மற்றும் இயக்கம்
- தியானம் மற்றும் விழிப்புணர்வு

### ஆதரவு அமைப்புகள்
- நம்பகமான நண்பர்களுடன் பேசுங்கள்
- தேவைப்பட்டால் தொழில்முறை உதவியை நாடுங்கள்
- ஆதரவு குழுக்களில் சேருங்கள்
- கூட்டாளர்களுடன் தொடர்பு கொள்ளுங்கள்

### தொழில்முறை உதவி
- சிகிச்சையைக் கருத்தில் கொள்ளுங்கள்
- மருத்துவர்களை அணுகவும்
- மருந்து விருப்பங்களை ஆராயுங்கள்
- அறிகுறிகளை கண்காணிக்கவும்

## எப்போது உதவி நாட வேண்டும்

- நிலையான மனநிலை மாற்றங்கள்
- கடுமையான பதட்டம் அல்லது மனச்சோர்வு
- சுய-தீங்கு எண்ணங்கள்
- தினசரி செயல்பாடுகளில் சிரமம்

உங்கள் மனநல ஆரோக்கியம் முக்கியம். தேவைப்படும்போது உதவி நாட தயங்க வேண்டாம்.''',
                'author': 'OvuMate மனநல குழு'
              };
            case 'si':
              return {
                'title': 'මානසික සෞඛ්‍යය සහ ඔබේ චක්‍රය',
                'summary': 'මානසික සෞඛ්‍යය සහ ඔසප් චක්‍ර අතර සම්බන්ධය තේරුම් ගැනීම.',
                'content': '''# මානසික සෞඛ්‍යය සහ ඔබේ චක්‍රය

ඔබේ ඔසප් චක්‍රය ඔබේ මානසික සෞඛ්‍යයට සැලකිය යුතු ලෙස බලපායි. මෙම සම්බන්ධය තේරුම් ගැනීම ඔබව වඩා හොඳින් රැකබලා ගැනීමට උපකාරී වේ.

## හෝර්මෝන වෙනස්කම් සහ මනෝභාවය

### ඊස්ට්‍රජන් සහ සෙරොටොනින්
- ඊස්ට්‍රජන් මට්ටම් සෙරොටොනින් නිෂ්පාදනයට බලපායි
- අඩු ඊස්ට්‍රජන් මනෝභාව වෙනස්වීම්වලට තුඩු දිය හැකිය
- මෙය සාමාන්‍ය සහ තාවකාලිකය

### ප්‍රොජෙස්ටරෝන් සහ කාංසාව
- ප්‍රොජෙස්ටරෝන් සන්සුන් කිරීමේ බලපෑම් ඇත
- අඩු මට්ටම් කාංසාව වැඩි කළ හැකිය
- මෙය තේරුම් ගැනීම රෝග ලක්ෂණ කළමනාකරණයට උපකාරී වේ

## සාමාන්‍ය මානසික සෞඛ්‍ය වෙනස්කම්

### ඔසප් පූර්ව සින්ඩ්‍රෝමය (PMS)
- මනෝභාව අචල බව
- කෝපය
- කාංසාව
- මානසික අවපීඩනය

### ඔසප් කාලයේදී
- තෙහෙට්ටුව
- චිත්තවේගීය සංවේදීතාව
- ආතතිය සංවේදීතාව
- සාන්ද්‍රණ දුෂ්කරතා

## මුහුණ දීමේ උපාය මාර්ග

### ස්වයං රැකවරණ භාවිතයන්
- නිත්‍ය නින්ද කාලසටහන
- සෞඛ්‍ය සම්පන්න ආහාර පුරුදු
- ව්‍යායාම සහ චලනය
- භාවනා සහ සිහිය

### ආධාරක පද්ධති
- විශ්වාසවන්ත මිතුරන් සමඟ කතා කරන්න
- අවශ්‍ය නම් වෘත්තීය උදව් අපේක්ෂා කරන්න
- ආධාරක කණ්ඩායම්වලට සම්බන්ධ වන්න
- සහකරුවන් සමඟ සන්නිවේදනය කරන්න

### වෘත්තීය උදව්

- චිකිත්සාව සලකා බලන්න
- වෛද්‍යවරුන් සම්බන්ධ කරගන්න
- ඖෂධ විකල්ප ගවේෂණය කරන්න
- රෝග ලක්ෂණ නිරීක්ෂණය කරන්න

## කවදා උදව් ලබා ගත යුතුද

- නිරන්තර මනෝභාව වෙනස්කම්
- දරුණු කාංසාව හෝ මානසික අවපීඩනය
- ස්වයං-හානි සිතුවිලි
- දෛනික ක්‍රියාකාරිත්වයේ දුෂ්කරතා

ඔබේ මානසික සෞඛ්‍යය වැදගත්. අවශ්‍ය වූ විට උදව් ලබා ගැනීමට පසුබට නොවන්න.''',
                'author': 'OvuMate මානසික සෞඛ්‍ය කණ්ඩායම'
              };
            default:
              return {
                'title': 'Mental Health and Your Cycle',
                'summary': 'Understanding the connection between mental health and menstrual cycles.',
                'content': '''# Mental Health and Your Cycle

Your menstrual cycle can significantly impact your mental health. Understanding this connection helps you take better care of yourself.

## Hormonal Changes and Mood

### Estrogen and Serotonin
- Estrogen levels affect serotonin production
- Lower estrogen can lead to mood changes
- This is normal and temporary

### Progesterone and Anxiety
- Progesterone has calming effects
- Lower levels can increase anxiety
- Understanding this helps manage symptoms

## Common Mental Health Changes

### Premenstrual Syndrome (PMS)
- Mood swings
- Irritability
- Anxiety
- Depression

### During Period
- Fatigue
- Emotional sensitivity
- Stress sensitivity
- Concentration difficulties

## Coping Strategies

### Self-Care Practices
- Regular sleep schedule
- Healthy eating habits
- Exercise and movement
- Meditation and mindfulness

### Support Systems
- Talk to trusted friends
- Seek professional help if needed
- Join support groups
- Communicate with partners

### Professional Help
- Consider therapy
- Consult with doctors
- Explore medication options
- Track symptoms

## When to Seek Help

- Persistent mood changes
- Severe anxiety or depression
- Thoughts of self-harm
- Difficulty functioning daily

Your mental health matters. Don't hesitate to seek help when needed.''',
                'author': 'OvuMate Mental Health Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_5',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.mentalHealth,
        difficulty: ArticleDifficulty.intermediate,
        readTime: 6,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['mental health', 'anxiety', 'depression', 'PMS', 'mood'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 6
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'கருவுறுதல் விழிப்புணர்வு முறைகள்',
                'summary': 'கருவுறுதலைக் கண்காணிக்கவும் உங்கள் இனப்பெருக்க ஆரோக்கியத்தைப் புரிந்து கொள்ளவும் இயற்கை முறைகள்.',
                'content': '''# கருவுறுதல் விழிப்புணர்வு முறைகள்

உங்கள் கருவுறுதலைப் புரிந்துகொள்வது குடும்ப திட்டமிடல் மற்றும் இனப்பெருக்க ஆரோக்கியம் பற்றி தகவலறிந்த முடிவுகளை எடுக்க உதவும்.

## கருவுறுதல் விழிப்புணர்வு என்றால் என்ன?

கருவுறுதல் விழிப்புணர்வு என்பது கருவுறும் மற்றும் கருவுறாத காலங்களை அடையாளம் காண உங்கள் மாதவிடாய் சுழற்சியைக் கண்காணிப்பதை உள்ளடக்குகிறது.

## கண்காணிப்பு முறைகள்

### அடிப்படை உடல் வெப்பநிலை (BBT)
- காலையில் முதலில் வெப்பநிலையை எடுக்கவும்
- தினசரி அளவீடுகளை பதிவு செய்யவும்
- கருவுறுதலுக்குப் பிறகு வெப்பநிலை உயர்வைக் கவனிக்கவும்

### கர்ப்பப்பை வாய் சளி கண்காணிப்பு
- கர்ப்பப்பை வாய் சளியில் மாற்றங்களைக் கவனிக்கவும்
- கருவுறும் சளி தெளிவானது, நீட்டிக்கக்கூடியது மற்றும் வழுக்கும்
- கருவுறாத சளி தடிமனானது மற்றும் ஒட்டும்

### காலண்டர் முறை
- பல மாதங்களில் சுழற்சி நீளத்தைக் கண்காணிக்கவும்
- கருவுறும் சாளரத்தைக் கணக்கிடவும்
- கருவுறுதலைச் சுற்றி அதிக கருவுறும் நாட்கள்

### கருவுறுதல் முன்னறிவிப்பு கருவிகள்
- லுட்டினைசிங் ஹார்மோனுக்கான சிறுநீர் சோதனை
- நேர்மறை சோதனை 24-48 மணி நேரத்திற்குள் கருவுறுதலைக் குறிக்கிறது
- பிற முறைகளுடன் இணைந்து பயன்படுத்தவும்

## நன்மைகள்

- இயற்கை மற்றும் ஹார்மோன் இல்லாதது
- உடல் விழிப்புணர்வை அதிகரிக்கிறது
- கருத்தரிப்பு அல்லது கருத்தடைக்கு பயன்படுத்தலாம்
- அறிவுடன் பெண்களை மேம்படுத்துகிறது

## பரிசீலனைகள்

- தினசரி கண்காணிப்பு மற்றும் உறுதிப்பாடு தேவை
- ஒழுங்கற்ற சுழற்சிகளுக்கு பொருத்தமானது அல்ல
- சரியான பயன்பாட்டில் செயல்திறன் மாறுபடும்
- துல்லியத்திற்காக முறைகளை இணைக்கவும்

## எப்போது உதவி நாட வேண்டும்

- ஒழுங்கற்ற சுழற்சிகள்
- வடிவங்களைக் கண்காணிப்பதில் சிரமம்
- 6 மாதங்களுக்கு மேல் கருத்தரிக்க முயற்சிக்கிறது
- நம்பகமான கருத்தடை தேவை

கருவுறுதல் விழிப்புணர்வு உங்கள் உடலைப் புரிந்துகொள்வதற்கான சக்திவாய்ந்த கருவியாக இருக்கும்.''',
                'author': 'OvuMate கருவுறுதல் குழு'
              };
            case 'si':
              return {
                'title': 'සංසිජ්ජතා දැනුවත්භාව ක්‍රම',
                'summary': 'සංසිජ්ජතාවය නිරීක්ෂණය කිරීමට සහ ඔබේ ප්‍රජනක සෞඛ්‍යය තේරුම් ගැනීමට ස්වාභාවික ක්‍රම.',
                'content': '''# සංසිජ්ජතා දැනුවත්භාව ක්‍රම

ඔබේ සංසිජ්ජතාවය තේරුම් ගැනීම පවුල් සැලසුම් කිරීම සහ ප්‍රජනක සෞඛ්‍යය පිළිබඳ දැනුවත් තීරණ ගැනීමට උපකාරී වේ.

## සංසිජ්ජතා දැනුවත්භාවය යනු කුමක්ද?

සංසිජ්ජතා දැනුවත්භාවය යනු සංසිජ්ජ සහ සංසිජ්ජ නොවන කාල පරිච්ඡේද හඳුනා ගැනීම සඳහා ඔබේ ඔසප් චක්‍රය නිරීක්ෂණය කිරීමයි.

## නිරීක්ෂණ ක්‍රම

### මූලික ශරීර උෂ්ණත්වය (BBT)
- උදේ පළමුව උෂ්ණත්වය ගන්න
- දෛනික කියවීම් ප්‍රස්ථාරය කරන්න
- ඩිම්බ මෝචනයෙන් පසු උෂ්ණත්වය ඉහළ යාම සොයන්න

### ගැබ්ගෙල ශ්ලේෂ්මල නිරීක්ෂණය
- ගැබ්ගෙල ශ්ලේෂ්මල වෙනස්කම් නිරීක්ෂණය කරන්න
- සංසිජ්ජ ශ්ලේෂ්මල පැහැදිලි, දිගටි සහ ලිස්සන සුලු ය
- සංසිජ්ජ නොවන ශ්ලේෂ්මල ඝන සහ ඇලෙන සුලු ය

### දින දර්ශන ක්‍රමය
- මාස කිහිපයක් පුරා චක්‍ර දිග නිරීක්ෂණය කරන්න
- සංසිජ්ජ කවුළුව ගණනය කරන්න
- වඩාත්ම සංසිජ්ජ දින ඩිම්බ මෝචනය වටා පවතී

### ඩිම්බ මෝචන පුරෝකථන කට්ටල
- ලුටීනයිසින් හෝර්මෝනය සඳහා මුත්‍රා පරීක්ෂා කරන්න
- ධනාත්මක පරීක්ෂණය පැය 24-48 ක් ඇතුළත ඩිම්බ මෝචනය පෙන්වයි
- වෙනත් ක්‍රම සමඟ සංයෝජනයෙන් භාවිතා කරන්න

## ප්‍රතිලාභ

- ස්වාභාවික සහ හෝර්මෝන රහිත
- ශරීර දැනුවත්භාවය වැඩි කරයි
- ගැබ්ගැනීම හෝ ප්‍රතිංධිසරණය සඳහා භාවිතා කළ හැකිය
- දැනුමෙන් කාන්තාවන් සවිබල ගන්වයි

## සැලකිල්ල

- දෛනික නිරීක්ෂණය සහ කැපවීම අවශ්‍ය වේ
- අක්‍රමවත් චක්‍ර සඳහා සුදුසු නොවිය හැක
- නිසි භාවිතයෙන් ඵලදායීතාවය වෙනස් වේ
- නිරවද්‍යතාව සඳහා ක්‍රම සංයෝජනය කිරීම සලකා බලන්න

## කවදා උදව් ලබා ගත යුතුද

- අක්‍රමවත් චක්‍ර
- රටා නිරීක්ෂණය කිරීමේ දුෂ්කරතා
- මාස 6 කට වඩා වැඩි කාලයක් ගැබ් ගැනීමට උත්සාහ කිරීම
- වඩා විශ්වාසදායක ප්‍රතිංධිසරණය අවශ්‍ය

සංසිජ්ජතා දැනුවත්භාවය ඔබේ ශරීරය තේරුම් ගැනීම සඳහා ප්‍රබල මෙවලමක් විය හැකිය.''',
                'author': 'OvuMate සංසිජ්ජතා කණ්ඩායම'
              };
            default:
              return {
                'title': 'Fertility Awareness Methods',
                'summary': 'Natural methods to track fertility and understand your reproductive health.',
                'content': '''# Fertility Awareness Methods

Understanding your fertility can help you make informed decisions about family planning and reproductive health.

## What is Fertility Awareness?

Fertility awareness involves tracking your menstrual cycle to identify fertile and infertile periods.

## Methods of Tracking

### Basal Body Temperature (BBT)
- Take temperature first thing in the morning
- Chart daily readings
- Look for temperature rise after ovulation

### Cervical Mucus Monitoring
- Observe changes in cervical mucus
- Fertile mucus is clear, stretchy, and slippery
- Infertile mucus is thick and sticky

### Calendar Method
- Track cycle length over several months
- Calculate fertile window
- Most fertile days are around ovulation

### Ovulation Predictor Kits
- Test urine for luteinizing hormone
- Positive test indicates ovulation within 24-48 hours
- Use in combination with other methods

## Benefits

- Natural and hormone-free
- Increases body awareness
- Can be used for conception or contraception
- Empowers women with knowledge

## Considerations

- Requires daily tracking and commitment
- May not be suitable for irregular cycles
- Effectiveness varies with proper use
- Consider combining methods for accuracy

## When to Seek Help

- Irregular cycles
- Difficulty tracking patterns
- Trying to conceive for over 6 months
- Need for more reliable contraception

Fertility awareness can be a powerful tool for understanding your body.''',
                'author': 'OvuMate Fertility Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_6',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.fertility,
        difficulty: ArticleDifficulty.intermediate,
        readTime: 5,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['fertility', 'ovulation', 'family planning', 'reproductive health'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 7
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'கர்ப்பகால ஊட்டச்சத்து வழிகாட்டி',
                'summary': 'ஆரோக்கியமான கர்ப்பம் மற்றும் குழந்தை வளர்ச்சிக்கான அத்தியாவசிய ஊட்டச்சத்து குறிப்புகள்.',
                'content': '''# கர்ப்பகால ஊட்டச்சத்து வழிகாட்டி

கர்ப்ப காலத்தில் சரியான ஊட்டச்சத்து தாய் மற்றும் குழந்தை இருவரின் ஆரோக்கியத்திற்கும் முக்கியமானது.

## கர்ப்ப காலத்தில் முக்கிய ஊட்டச்சத்துக்கள்

### ஃபோலிக் அமிலம்
- நரம்பு குழாய் குறைபாடுகளைத் தடுக்கிறது
- தினமும் 400-800 mcg எடுக்கவும்
- ஆதாரங்கள்: கீரைகள், வலுவூட்டப்பட்ட தானியங்கள், சப்ளிமெண்ட்ஸ்

### இரும்பு
- இரத்த சோகையைத் தடுக்கிறது
- குழந்தையின் வளர்ச்சியை ஆதரிக்கிறது
- ஆதாரங்கள்: மெலிந்த இறைச்சி, பீன்ஸ், வலுவூட்டப்பட்ட தானியங்கள்

### கால்சியம்
- வலுவான எலும்புகள் மற்றும் பற்களை உருவாக்குகிறது
- தசை மற்றும் நரம்பு செயல்பாட்டை ஆதரிக்கிறது
- ஆதாரங்கள்: பால் பொருட்கள், கீரைகள், வலுவூட்டப்பட்ட உணவுகள்

### புரதம்
- குழந்தையின் வளர்ச்சிக்கு அவசியம்
- தாயின் திசுக்களை ஆதரிக்கிறது
- ஆதாரங்கள்: மெலிந்த இறைச்சி, மீன், முட்டை, பயறு வகைகள்

### ஒமேகா-3 கொழுப்பு அமிலங்கள்
- மூளை வளர்ச்சியை ஆதரிக்கிறது
- முன்கூட்டிய பிறப்பு அபாயத்தைக் குறைக்கிறது
- ஆதாரங்கள்: மீன், அக்ரூட், ஆளி விதைகள்

## தவிர்க்க வேண்டிய உணவுகள்

- பச்சை அல்லது குறைவாக சமைத்த இறைச்சி
- பாஸ்சரைஸ் செய்யப்படாத பால் பொருட்கள்
- பச்சை முட்டைகள்
- அதிக பாதரசம் கொண்ட மீன்
- அதிகப்படியான காஃபின்

## ஆரோக்கியமான உணவு குறிப்புகள்

1. சிறிய, அடிக்கடி உணவுகளை சாப்பிடுங்கள்
2. தண்ணீர் குடித்து நீரேற்றமாக இருங்கள்
3. பதப்படுத்தப்பட்ட உணவுகளை விட முழு உணவுகளை தேர்வு செய்யுங்கள்
4. உங்கள் உடலின் பசி குறிப்புகளைக் கேளுங்கள்
5. இருவருக்கும் சாப்பிட வேண்டாம் - தரத்தில் கவனம் செலுத்துங்கள்

## எடை அதிகரிப்பு வழிகாட்டுதல்கள்

- முதல் மூன்று மாதம்: 1-4 பவுண்டுகள்
- இரண்டாவது மூன்று மாதம்: வாரத்திற்கு 1 பவுண்டு
- மூன்றாவது மூன்று மாதம்: வாரத்திற்கு 1 பவுண்டு
- மொத்தம்: சாதாரண எடைக்கு 25-35 பவுண்டுகள்

## எப்போது உதவி நாட வேண்டும்

- கடுமையான குமட்டல் மற்றும் வாந்தி
- சாப்பிடுவதில் சிரமம்
- அசாதாரண உணவு ஆசைகள்
- குறிப்பிடத்தக்க எடை இழப்பு

கர்ப்ப காலத்தில் நல்ல ஊட்டச்சத்து உங்கள் குழந்தையின் ஆரோக்கியத்திற்கு அடித்தளம் அமைக்கிறது.''',
                'author': 'OvuMate கர்ப்பகால குழு'
              };
            case 'si':
              return {
                'title': 'ගර්භණී පෝෂණ මාර්ගෝපදේශය',
                'summary': 'සෞඛ්‍ය සම්පන්න ගැබ්ගැනීමක් සහ ළදරු වර්ධනය සඳහා අත්‍යවශ්‍ය පෝෂණ උපදෙස්.',
                'content': '''# ගර්භණී පෝෂණ මාර්ගෝපදේශය

ගැබ්ගැනීමේ දී නිසි පෝෂණය මව සහ දරුවා යන දෙදෙනාගේම සෞඛ්‍යය සඳහා ඉතා වැදගත් වේ.

## ගැබ්ගැනීමේ දී ප්‍රධාන පෝෂ්‍ය පදාර්ථ

### ෆොලික් අම්ලය
- ස්නායු නාල දෝෂ වැළැක්වීම
- දිනකට mcg 400-800 ගන්න
- ප්‍රභව: කොළ එළවළු, ශක්තිමත් කළ ධාන්‍ය, අතිරේක

### යකඩ
- රක්තහීනතාවය වළක්වයි
- දරුවාගේ වර්ධනයට සහාය වේ
- ප්‍රභව: මේදය අඩු මස්, බෝංචි, ශක්තිමත් කළ ධාන්‍ය

### කැල්සියම්
- ශක්තිමත් ඇට සහ දත් ගොඩනඟයි
- මාංශ පේශි සහ ස්නායු ක්‍රියාකාරිත්වයට සහාය වේ
- ප්‍රභව: කිරි නිෂ්පාදන, කොළ එළවළු, ශක්තිමත් කළ ආහාර

### ප්‍රෝටීන්
- දරුවාගේ වර්ධනය සඳහා අත්‍යවශ්‍ය
- මාතෘ පටක සඳහා සහාය
- ප්‍රභව: මේදය අඩු මස්, මාළු, බිත්තර, රනිල කුලයේ ශාක

### ඔමේගා-3 මේද අම්ල
- මොළයේ වර්ධනයට සහාය වේ
- පූර්ව කාලීන උපත් අවදානම අඩු කරයි
- ප්‍රභව: මාළු, වට ඇට, හණ බීජ

## වළක්වා ගත යුතු ආහාර

- අමු හෝ අඩුවෙන් පිසින ලද මස්
- පාස්චරීකරණය නොකළ කිරි නිෂ්පාදන
- අමු බිත්තර
- අධික රසදිය සහිත මාළු
- අධික කැෆේන්

## නිරෝගී ආහාර ගැනීමේ උපදෙස්

1. කුඩා, නිතර ආහාර ගන්න
2. ජලය පානය කර ජලනය වන්න
3. සැකසූ ආහාර වලට වඩා සම්පූර්ණ ආහාර තෝරන්න
4. ඔබේ ශරීරයේ කුසගින්න සං කේත වලට සවන් දෙන්න
5. දෙදෙනාටම කන්න එපා - ගුණාත්මකභාවය කෙරෙහි අවධානය යොමු කරන්න

## බර වැඩිවීමේ මාර්ගෝපදේශ

- පළමු ත්‍රෛමාසිකය: පවුම් 1-4
- දෙවන ත්‍රෛමාසිකය: සතියකට පවුම් 1
- තෙවන ත්‍රෛමාසිකය: සතියකට පවුම් 1
- මුළු: සාමාන්‍ය බර සඳහා පවුම් 25-35

## කවදා උදව් ලබා ගත යුතුද

- දරුණු ඔක්කාරය සහ වමනය
- ආහාර ගැනීමේ දුෂ්කරතා
- අසාමාන්‍ය ආහාර ආශාවන්
- සැලකිය යුතු බර අඩුවීම

ගැබ්ගැනීමේ දී හොඳ පෝෂණය ඔබේ දරුවාගේ සෞඛ්‍යය සඳහා පදනම සකසයි.''',
                'author': 'OvuMate ගර්භණී කණ්ඩායම'
              };
            default:
              return {
                'title': 'Pregnancy Nutrition Guide',
                'summary': 'Essential nutrition tips for a healthy pregnancy and baby development.',
                'content': '''# Pregnancy Nutrition Guide

Proper nutrition during pregnancy is crucial for both mother and baby's health.

## Key Nutrients During Pregnancy

### Folic Acid
- Prevents neural tube defects
- Take 400-800 mcg daily
- Sources: Leafy greens, fortified cereals, supplements

### Iron
- Prevents anemia
- Supports baby's growth
- Sources: Lean meats, beans, fortified grains

### Calcium
- Builds strong bones and teeth
- Supports muscle and nerve function
- Sources: Dairy, leafy greens, fortified foods

### Protein
- Essential for baby's growth
- Supports maternal tissue
- Sources: Lean meats, fish, eggs, legumes

### Omega-3 Fatty Acids
- Supports brain development
- Reduces preterm birth risk
- Sources: Fish, walnuts, flaxseeds

## Foods to Avoid

- Raw or undercooked meat
- Unpasteurized dairy
- Raw eggs
- High-mercury fish
- Excessive caffeine

## Healthy Eating Tips

1. Eat small, frequent meals
2. Stay hydrated with water
3. Choose whole foods over processed
4. Listen to your body's hunger cues
5. Don't eat for two - focus on quality

## Weight Gain Guidelines

- First trimester: 1-4 pounds
- Second trimester: 1 pound per week
- Third trimester: 1 pound per week
- Total: 25-35 pounds for normal weight

## When to Seek Help

- Severe nausea and vomiting
- Difficulty eating
- Unusual food cravings
- Significant weight loss

Good nutrition during pregnancy sets the foundation for your baby's health.''',
                'author': 'OvuMate Pregnancy Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_7',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.pregnancy,
        difficulty: ArticleDifficulty.intermediate,
        readTime: 6,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['pregnancy', 'nutrition', 'prenatal care', 'baby development'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 8
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'ஆரோக்கியமான உறவுகளை உருவாக்குதல்',
                'summary': 'வெவ்வேறு வாழ்க்கை நிலைகளில் ஆரோக்கியமான உறவுகளை பராமரிப்பதற்கான குறிப்புகள்.',
                'content': '''# ஆரோக்கியமான உறவுகளை உருவாக்குதல்

ஆரோக்கியமான உறவுகள் ஒட்டுமொத்த நல்வாழ்வு மற்றும் மகிழ்ச்சிக்கு அவசியம்.

## உறவுகளின் வகைகள்

### காதல் உறவுகள்
- தொடர்பு முக்கியம்
- எல்லைகளை மதிக்கவும்
- தொடர்ந்து பாராட்டு காட்டுங்கள்
- முரண்பாடுகளை சேர்ந்து தீர்க்கவும்

### நட்பு
- நல்ல கேட்பவராக இருங்கள்
- தேவைப்படும்போது வருங்கள்
- ஆரோக்கியமான எல்லைகளை பராமரிக்கவும்
- நேரம் மற்றும் முயற்சி முதலீடு செய்யுங்கள்

### குடும்ப உறவுகள்
- மன்னிப்பு பயிற்சி செய்யுங்கள்
- ஆரோக்கியமான எல்லைகளை அமைக்கவும்
- வெளிப்படையாக தொடர்பு கொள்ளுங்கள்
- அன்பு மற்றும் மரியாதை காட்டுங்கள்

## தொடர்பு திறன்கள்

### செயலில் கேட்டல்
- முழு கவனம் கொடுங்கள்
- குறுக்கிடாதீர்கள்
- தெளிவுபடுத்தும் கேள்விகளைக் கேளுங்கள்
- நீங்கள் கேட்டதை பிரதிபலிக்கவும்

### உணர்வுகளை வெளிப்படுத்துதல்
- "நான்" அறிக்கைகளை பயன்படுத்துங்கள்
- தேவைகள் பற்றி குறிப்பிட்டு கூறுங்கள்
- சரியான நேரத்தை தேர்வு செய்யுங்கள்
- அமைதியாகவும் மரியாதையுடனும் இருங்கள்

### மோதல் தீர்வு
- பிரச்சினைகளை உடனடியாக நிவர்த்தி செய்யுங்கள்
- நபரை அல்ல, பிரச்சினையில் கவனம் செலுத்துங்கள்
- பொதுவான இடத்தைக் கண்டறியுங்கள்
- தேவைப்படும்போது கருத்து வேறுபாட்டை ஏற்கவும்

## நம்பிக்கையை உருவாக்குதல்

- வாக்குறுதிகளை காக்கவும்
- நேர்மையாகவும் வெளிப்படையாகவும் இருங்கள்
- தனியுரிமையை மதிக்கவும்
- வார்த்தைகள் மற்றும் செயல்களில் நிலைத்தன்மையை காட்டுங்கள்

## உறவுகளில் சுய பராமரிப்பு

- உங்கள் அடையாளத்தை பராமரிக்கவும்
- ஆரோக்கியமான எல்லைகளை அமைக்கவும்
- சுய இரக்கத்தை பயிற்சி செய்யுங்கள்
- உறவுகளில் உங்களை இழக்காதீர்கள்

## எச்சரிக்கை அறிகுறிகள்

- தொடர்ச்சியான விமர்சனம்
- கட்டுப்பாடு மற்றும் கையாளுதல்
- மரியாதை இல்லாமை
- உணர்ச்சி அல்லது உடல் துஷ்பிரயோகம்

## எப்போது உதவி நாட வேண்டும்

- தொடர்பு சிரமங்கள்
- நம்பிக்கை பிரச்சினைகள்
- ஆரோக்கியமற்ற வடிவங்கள்
- உறவு ஆலோசனை தேவைகள்

ஆரோக்கியமான உறவுகளுக்கு வேலை தேவை ஆனால் அபரிமிதமான மகிழ்ச்சியையும் ஆதரவையும் தருகின்றன.''',
                'author': 'OvuMate உறவுகள் குழு'
              };
            case 'si':
              return {
                'title': 'සෞඛ්‍ය සම්පන්න සබඳතා ගොඩනැගීම',
                'summary': 'විවිධ ජීවන අවධීන්හි සෞඛ්‍ය සම්පන්න සබඳතා පවත්වා ගැනීම සඳහා උපදෙස්.',
                'content': '''# සෞඛ්‍ය සම්පන්න සබඳතා ගොඩනැගීම

සෞඛ්‍ය සම්පන්න සබඳතා සමස්ත යහපැවැත්ම සහ සතුට සඳහා අත්‍යවශ්‍ය වේ.

## සබඳතා වර්ග

### ආදර සබඳතා
- සන්නිවේදනය ප්‍රධානයයි
- සීමාවන් ට ගරු කරන්න
- නිතර අගය කිරීම පෙන්වන්න
- එකට ගැටුම් විසඳන්න

### මිත්‍රත්වය
- හොඳ සවන්දෙන්නෙකු වන්න
- අවශ්‍ය විට පෙනී සිටින්න
- සෞඛ්‍ය සම්පන්න සීමාවන් පවත්වා ගන්න
- කාලය සහ උත්සාහය ආයෝජනය කරන්න

### පවුල් සබඳතා
- සමාව දීම පුහුණු කරන්න
- සෞඛ්‍ය සම්පන්න සීමාවන් සකසන්න
- විවෘතව සන්නිවේදනය කරන්න
- ආදරය සහ ගෞරවය පෙන්වන්න

## සන්නිවේදන කුසලතා

### ක්‍රියාකාරී සවන්දීම
- සම්පූර්ණ අවධානය දෙන්න
- බාධා නොකරන්න
- පැහැදිලි කිරීමේ ප්‍රශ්න අසන්න
- ඔබ ඇසූ දේ පිළිබිඹු කරන්න

### හැඟීම් ප්‍රකාශ කිරීම
- "මම" ප්‍රකාශන භාවිතා කරන්න
- අවශ්‍යතා ගැන නිශ්චිතව කියන්න
- නිවැරදි කාලය තෝරන්න
- සන්සුන්ව සහ ගෞරවයෙන් සිටින්න

### ගැටුම් නිරාකරණය
- ප්‍රශ්න වහාම විසඳන්න
- පුද්ගලයාට නොව, ප්‍රශ්නයට අවධානය යොමු කරන්න
- පොදු පදනමක් සොයා ගන්න
- අවශ්‍ය විට එකඟ නොවීමට එකඟ වන්න

## විශ්වාසය ගොඩනැගීම

- ප්‍රතිඥා රඳවා ගන්න
- අවංක සහ විනිවිදභාවයෙන් සිටින්න
- පෞද්ගලිකත්වයට ගරු කරන්න
- වචන සහ ක්‍රියාවන්හි ස්ථාවරත්වය පෙන්වන්න

## සබඳතාවල ස්වයං රැකවරණය

- ඔබේ අනන්‍යතාවය පවත්වා ගන්න
- සෞඛ්‍ය සම්පන්න සීමාවන් සකසන්න
- ස්වයං දයාව පුහුණු කරන්න
- සබඳතාවල ඔබව නොහරින්න

## අනතුරු ඇඟවීමේ සං කේත

- නිරන්තර විවේචන
- පාලනය සහ හැසිරවීම
- ගෞරවය නොමැතිකම
- චිත්තවේගීය හෝ ශාරීරික අපයෝජනය

## කවදා උදව් ලබා ගත යුතුද

- සන්නිවේදන දුෂ්කරතා
- විශ්වාස ගැටළු
- අසෞඛ්‍ය රටා
- සබඳතා උපදේශන අවශ්‍යතා

සෞඛ්‍ය සම්පන්න සබඳතාවලට වැඩ අවශ්‍ය නමුත් අතිමහත් ප්‍රීතිය සහ සහාය ගෙන එයි.''',
                'author': 'OvuMate සබඳතා කණ්ඩායම'
              };
            default:
              return {
                'title': 'Building Healthy Relationships',
                'summary': 'Tips for maintaining healthy relationships during different life stages.',
                'content': '''# Building Healthy Relationships

Healthy relationships are essential for overall well-being and happiness.

## Types of Relationships

### Romantic Relationships
- Communication is key
- Respect boundaries
- Show appreciation regularly
- Work through conflicts together

### Friendships
- Be a good listener
- Show up when needed
- Maintain healthy boundaries
- Invest time and effort

### Family Relationships
- Practice forgiveness
- Set healthy boundaries
- Communicate openly
- Show love and respect

## Communication Skills

### Active Listening
- Give full attention
- Don't interrupt
- Ask clarifying questions
- Reflect back what you heard

### Expressing Feelings
- Use "I" statements
- Be specific about needs
- Choose the right time
- Stay calm and respectful

### Conflict Resolution
- Address issues promptly
- Focus on the problem, not the person
- Find common ground
- Agree to disagree when necessary

## Building Trust

- Keep promises
- Be honest and transparent
- Respect privacy
- Show consistency in words and actions

## Self-Care in Relationships

- Maintain your identity
- Set healthy boundaries
- Practice self-compassion
- Don't lose yourself in relationships

## Warning Signs

- Constant criticism
- Control and manipulation
- Lack of respect
- Emotional or physical abuse

## When to Seek Help

- Communication difficulties
- Trust issues
- Unhealthy patterns
- Relationship counseling needs

Healthy relationships require work but bring immense joy and support.''',
                'author': 'OvuMate Relationships Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_8',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.relationships,
        difficulty: ArticleDifficulty.beginner,
        readTime: 5,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['relationships', 'communication', 'trust', 'boundaries'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 9
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'சிறந்த ஆரோக்கியத்திற்கான வாழ்க்கை முறை மாற்றங்கள்',
                'summary': 'உங்கள் நல்வாழ்வை கணிசமாக மேம்படுத்தக்கூடிய எளிய வாழ்க்கை முறை மாற்றங்கள்.',
                'content': '''# சிறந்த ஆரோக்கியத்திற்கான வாழ்க்கை முறை மாற்றங்கள்

தினசரி பழக்கங்களில் சிறிய மாற்றங்கள் உங்கள் ஆரோக்கியம் மற்றும் நல்வாழ்வில் குறிப்பிடத்தக்க முன்னேற்றங்களுக்கு வழிவகுக்கும்.

## தூக்க மேம்படுத்தல்

### தூக்க சுகாதாரம்
- நிலையான தூக்க அட்டவணையை பராமரிக்கவும்
- Create a relaxing bedtime routine
- Keep bedroom cool and dark
- Avoid screens before bed

### Sleep Duration
- Adults need 7-9 hours per night
- Quality matters more than quantity
- Listen to your body's needs
- Prioritize sleep over other activities

## Stress Management

### Daily Practices
- Practice deep breathing
- Take regular breaks
- Engage in hobbies
- Spend time in nature

### Mindfulness
- Start with 5 minutes daily
- Focus on present moment
- Accept thoughts without judgment
- Practice gratitude

## Physical Activity

### Movement Throughout Day
- Take stairs instead of elevator
- Walk during phone calls
- Park farther from destination
- Use standing desk when possible

### Regular Exercise
- Aim for 150 minutes weekly
- Mix cardio and strength training
- Find activities you enjoy
- Start slowly and build gradually

## Nutrition Habits

### Meal Planning
- Plan meals ahead of time
- Prepare healthy snacks
- Cook in batches
- Keep healthy options visible

### Mindful Eating
- Eat without distractions
- Chew slowly
- Listen to hunger cues
- Stop when satisfied

## Social Connections

### Quality Over Quantity
- Nurture meaningful relationships
- Join community groups
- Volunteer your time
- Stay connected with family

### Digital Balance
- Limit social media use
- Have device-free meals
- Set boundaries for work
- Prioritize real connections

## Environmental Factors

### Home Environment
- Keep living spaces clean
- Add plants for air quality
- Use natural light when possible
- Create comfortable spaces

### Work Environment
- Optimize ergonomics
- Take regular breaks
- Maintain good posture
- Reduce noise and distractions

## Consistency is Key

- Start with one change
- Build on successes
- Be patient with yourself
- Celebrate small wins

நிலையான முயற்சி மூலம் நீடித்த மாற்றம் படிப்படியாக நடக்கிறது என்பதை நினைவில் கொள்ளுங்கள்.''',
                'author': 'OvuMate வாழ்க்கைமுறை குழு'
              };
            case 'si':
              return {
                'title': 'වඩා හොඳ සෞඛ්‍යයක් සඳහා ජීවන රටා වෙනස්කම්',
                'summary': 'ඔබේ යහපැවැත්ම සැලකිය යුතු ලෙස වැඩිදියුණු කළ හැකි සරල ජීවන රටා වෙනස්කම්.',
                'content': '''# වඩා හොඳ සෞඛ්‍යයක් සඳහා ජීවන රටා වෙනස්කම්

දෛනික පුරුදු වල කුඩා වෙනස්කම් ඔබේ සෞඛ්‍යය සහ යහපැවැත්මේ සැලකිය යුතු වැඩිදියුණු කිරීම් වලට මග පාදයි.

දිගුකාලීන වෙනස් ස්ථාවර උත්සාහය හරහා ක්‍රමයෙන් සිදු වන බව මතක තබා ගන්න.''',
                'author': 'OvuMate ජීවන රටා කණ්ඩායම'
              };
            default:
              return {
                'title': 'Lifestyle Changes for Better Health',
                'summary': 'Simple lifestyle modifications that can significantly improve your well-being.',
                'content': '''# Lifestyle Changes for Better Health

Small changes in daily habits can lead to significant improvements in your health and well-being.

Remember, lasting change happens gradually through consistent effort.''',
                'author': 'OvuMate Lifestyle Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_9',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.lifestyle,
        difficulty: ArticleDifficulty.beginner,
        readTime: 7,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['lifestyle', 'wellness', 'habits', 'self-care'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 10
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'PCOS-ஐ புரிந்துகொள்ளுதல்',
                'summary': 'பாலிசிஸ்டிக் ஓவரி சிண்ட்ரோம் அறிகுறிகள் மற்றும் மேலாண்மைக்கான விரிவான வழிகாட்டி.',
                'content': '''# PCOS-ஐ புரிந்துகொள்ளுதல்

பாலிசிஸ்டிக் ஓவரி சிண்ட்ரோம் (PCOS) இனப்பெருக்க வயதுடைய பெண்களில் 6-12% ஐ பாதிக்கிறது.

## PCOS என்றால் என்ன?

PCOS என்பது சிறிய நீர்க்கட்டிகளுடன் கூடிய பெரிதான கருப்பைகளை ஏற்படுத்தும் ஹார்மோன் கோளாறு ஆகும்.

## பொதுவான அறிகுறிகள்

### ஒழுங்கற்ற மாதவிடாய்
- மாதவிடாய் அரிதாக அல்லது நீண்டதாக இருக்கலாம்
- மாதவிடாய் ஏற்படும்போது அதிக இரத்தப்போக்கு
- சுழற்சியை கணிப்பதில் சிரமம்

### அதிகப்படியான ஆண்ட்ரோஜன்
- உயர்ந்த ஆண் ஹார்மோன் அளவுகள்
- அதிகப்படியான முக/உடல் முடி
- கடுமையான முகப்பரு
- ஆண்-வடிவ வழுக்கை

### பாலிசிஸ்டிக் கருப்பைகள்
- பெரிதாக்கப்பட்ட கருப்பைகள்
- பல சிறிய நீர்க்கட்டிகள்
- அறிகுறிகளை ஏற்படுத்தாமல் இருக்கலாம்

## காரணங்கள்

### இன்சுலின் எதிர்ப்பு
- அதிகப்படியான இன்சுலின் ஆண்ட்ரோஜன் உற்பத்தியை அதிகரிக்கலாம்
- கருவுறுதல் பிரச்சினைகளுக்கு பங்களிக்கலாம்
- அதிக எடை கொண்ட பெண்களில் பொதுவானது

### பரம்பரை
- குடும்ப வரலாறு அபாயத்தை அதிகரிக்கிறது
- மரபணு காரணிகள் பங்கு வகிக்கின்றன
- சுற்றுச்சூழல் காரணிகள் பங்களிக்கலாம்

### வீக்கம்
- குறைந்த-நிலை வீக்கம் பொதுவானது
- ஆண்ட்ரோஜன் உற்பத்தியை தூண்டலாம்
- பிற சுகாதார நிலைகளுடன் இணைக்கப்பட்டுள்ளது

## சிகிச்சை விருப்பங்கள்

### வாழ்க்கை முறை மாற்றங்கள்
- எடை இழப்பு (5-10% அறிகுறிகளை மேம்படுத்தலாம்)
- வழக்கமான உடற்பயிற்சி
- ஆரோக்கியமான உணவு (குறைந்த கிளைசெமிக் குறியீடு)
- மன அழுத்த மேலாண்மை

### மருந்துகள்
- பிறப்பு கட்டுப்பாட்டு மாத்திரைகள் (மாதவிடாய் ஒழுங்குபடுத்த)
- மெட்ஃபார்மின் (இன்சுலின் எதிர்ப்பை மேம்படுத்த)
- க்ளோமிஃபீன் (கருவுறுதல் சிகிச்சை)
- எதிர்-ஆண்ட்ரோஜன்கள் (முடி வளர்ச்சியை குறைக்க)

## சிக்கல்கள்

- வகை 2 நீரிழிவு நோய்
- உயர் இரத்த அழுத்தம்
- இதய நோய்
- தூக்கத்தில் மூச்சுத்திணறல்
- மனச்சோர்வு மற்றும் பதட்டம்
- எண்டோமெட்ரியல் புற்றுநோய்

## PCOS உடன் வாழ்தல்

### சுய பராமரிப்பு
- வழக்கமான மருத்துவ பரிசோதனைகள்
- அறிகுறிகளை கண்காணிக்கவும்
- ஆரோக்கியமான எடையை பராமரிக்கவும்
- மன அழுத்தம் குறைப்பை பயிற்சி செய்யுங்கள்

### ஆதரவு
- ஆதரவு குழுக்களில் சேருங்கள்
- குடும்பம் மற்றும் நண்பர்களுக்கு கற்பிக்கவும்
- சுகாதார குழுவுடன் பணியாற்றவும்
- ஆராய்ச்சி பற்றி தகவலறிந்திருங்கள்

## எப்போது உதவி நாட வேண்டும்

- ஒழுங்கற்ற அல்லது இல்லாத மாதவிடாய்
- கருத்தரிப்பதில் சிரமம்
- கடுமையான அறிகுறிகள்
- புதிய அல்லது மோசமான அறிகுறிகள்

ஆரம்ப நோயறிதல் மற்றும் சிகிச்சை அறிகுறிகளை நிர்வகிக்கவும் சிக்கல்களைத் தடுக்கவும் உதவும்.''',
                'author': 'OvuMate மருத்துவ குழு'
              };
            case 'si':
              return {
                'title': 'PCOS තේරුම් ගැනීම',
                'summary': 'බහු සිස්ට් ඩිම්බකෝෂ සින්ඩ්‍රෝමය රෝග ලක්ෂණ සහ කළමනාකරණය සඳහා සවිස්තරාත්මක මාර්ගෝපදේශය.',
                'content': '''# PCOS තේරුම් ගැනීම

බහු සිස්ට් ඩිම්බකෝෂ සින්ඩ්‍රෝමය (PCOS) ප්‍රජනක වයසේ කාන්තාවන්ගෙන් 6-12% කට බලපායි.

## PCOS යනු කුමක්ද?

PCOS යනු පිටත දාර මත කුඩා පුහුරු සහිත විශාල ඩිම්බකෝෂ ඇති කරන හෝර්මෝන ආබාධයකි.

## සාමාන්‍ය රෝග ලක්ෂණ

### අක්‍රමවත් ඔසප්
- ඔසප් දුර්ලභ හෝ දීර්ඝ විය හැකිය
- ඔසප් ඇති වූ විට අධික ලේ ගැලීම
- චක්‍රය පුරෝකථනය කිරීමේ දුෂ්කරතා

### අතිරික්ත ඇන්ඩ්‍රොජන්
- ඉහළ පිරිමි හෝර්මෝන මට්ටම්
- අධික මුහුණේ/ශරීර රෝම
- දරුණු කුරුලෑ
- පිරිමි-රටා ගොළුබව

### බහු සිස්ට් ඩිම්බකෝෂ
- විශාල ඩිම්බකෝෂ
- බහු කුඩා පුහුරු
- රෝග ලක්ෂණ ඇති නොකළ හැක

## හේතු

### ඉන්සියුලින් ප්‍රතිරෝධය
- අධික ඉන්සියුලින් ඇන්ඩ්‍රොජන් නිෂ්පාදනය වැඩි කළ හැකිය
- ඩිම්බ මෝචන ගැටළු වලට දායක විය හැකිය
- අධික බර කාන්තාවන් තුළ සාමාන්‍යය

### පාරම්පරිකත්වය
- පවුල් ඉතිහාසය අවදානම වැඩි කරයි
- ජානමය සාධක භූමිකාවක් ඉටු කරයි
- පාරිසරික සාධක දායක විය හැකිය

### දැවිල්ල
- අඩු-මට්ටමේ දැවිල්ල සාමාන්‍යය
- ඇන්ඩ්‍රොජන් නිෂ්පාදනය උත්තේජනය කළ හැකිය
- වෙනත් සෞඛ්‍ය තත්ත්වයන් සමඟ සම්බන්ධ

## ප්‍රතිකාර විකල්ප

### ජීවන රටා වෙනස්කම්
- බර අඩුවීම (5-10% රෝග ලක්ෂණ වැඩිදියුණු කළ හැකිය)
- නිත්‍ය ව්‍යායාම
- සෞඛ්‍ය සම්පන්න ආහාර (අඩු ග්ලයිසමික් දර්ශකය)
- ආතතිය කළමනාකරණය

### ඖෂධ

- උපත් පාලන පෙති (ඔසප් නියාමනය කිරීම)
- මෙට්ෆෝමින් (ඉන්සියුලින් ප්‍රතිරෝධය වැඩිදියුණු කිරීම)
- ක්ලෝමිෆීන් (සංසිජ්ජතා ප්‍රතිකාර)
- ප්‍රති-ඇන්ඩ්‍රොජන් (රොම් වර්ධනය අඩු කිරීම)

## සංකූලතා

- වර්ගය 2 දියවැඩියාව
- ඉහළ රුධිර පීඩනය
- හෘද රෝග
- නිදාගැනීමේ ඇප්නියා
- මානසික අවපීඩනය සහ කාංසාව
- එන්ඩොමෙට්‍රියල් පිළිකා

## PCOS සමඟ ජීවත් වීම

### ස්වයං රැකවරණය
- නිත්‍ය වෛද්‍ය පරීක්ෂණ
- රෝග ලක්ෂණ නිරීක්ෂණය කරන්න
- සෞඛ්‍ය සම්පන්න බරක් පවත්වා ගන්න
- ආතතිය අඩු කිරීම පුහුණු කරන්න

### සහාය
- ආධාරක කණ්ඩායම්වලට සම්බන්ධ වන්න
- පවුලේ අය සහ මිතුරන්ට උගන්වන්න
- සෞඛ්‍ය සේවා කණ්ඩායම සමඟ වැඩ කරන්න
- පර්යේෂණ පිළිබඳව දැනුවත්ව සිටින්න

## කවදා උදව් ලබා ගත යුතුද

- අක්‍රමවත් හෝ නොමැති ඔසප්
- ගැබ් ගැනීමේ දුෂ්කරතා
- දරුණු රෝග ලක්ෂණ
- නව හෝ නරක අතට හැරෙන රෝග ලක්ෂණ

ඉක්මන් රෝග විනිශ්චය සහ ප්‍රතිකාර රෝග ලක්ෂණ කළමනාකරණය කිරීමට සහ සංකූලතා වැළැක්වීමට උපකාරී වේ.''',
                'author': 'OvuMate වෛද්‍ය කණ්ඩායම'
              };
            default:
              return {
                'title': 'Understanding PCOS',
                'summary': 'Comprehensive guide to Polycystic Ovary Syndrome symptoms and management.',
                'content': '''# Understanding PCOS

Polycystic Ovary Syndrome (PCOS) affects 6-12% of women of reproductive age.

## What is PCOS?

PCOS is a hormonal disorder causing enlarged ovaries with small cysts on the outer edges.

## Common Symptoms

### Irregular Periods
- Periods may be infrequent or prolonged
- Heavy bleeding when periods occur
- Difficulty predicting cycle

### Excess Androgen
- Elevated male hormone levels
- Hirsutism (excess facial/body hair)
- Severe acne
- Male-pattern baldness

### Polycystic Ovaries
- Enlarged ovaries
- Multiple small cysts
- May not cause symptoms

## Causes

### Insulin Resistance
- Excess insulin may increase androgen production
- May contribute to ovulation problems
- Common in overweight women

### Heredity
- Family history increases risk
- Genetic factors play a role
- Environmental factors may contribute

### Inflammation
- Low-grade inflammation is common
- May stimulate androgen production
- Linked to other health conditions

## Treatment Options

### Lifestyle Changes
- Weight loss (5-10% can improve symptoms)
- Regular exercise
- Healthy diet (low glycemic index)
- Stress management

### Medications
- Birth control pills (regulate periods)
- Metformin (improve insulin resistance)
- Clomiphene (fertility treatment)
- Anti-androgens (reduce hair growth)

## Complications

- Type 2 diabetes
- High blood pressure
- Heart disease
- Sleep apnea
- Depression and anxiety
- Endometrial cancer

## Living with PCOS

### Self-Care
- Regular medical check-ups
- Monitor symptoms
- Maintain healthy weight
- Practice stress reduction

### Support
- Join support groups
- Educate family and friends
- Work with healthcare team
- Stay informed about research

## When to Seek Help

- Irregular or absent periods
- Difficulty conceiving
- Severe symptoms
- New or worsening symptoms

Early diagnosis and treatment can help manage symptoms and prevent complications.''',
                'author': 'OvuMate Medical Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_10',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.medicalConditions,
        difficulty: ArticleDifficulty.advanced,
        readTime: 8,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['PCOS', 'hormones', 'fertility', 'medical condition'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 11
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'பெண்களின் நல்வாழ்வுக்கான யோகா',
                'summary': 'பெண்களின் ஆரோக்கியத்திற்கு குறிப்பாக பயனுள்ள யோகா நிலைகள் மற்றும் பயிற்சிகள்.',
                'content': '''# பெண்களின் நல்வாழ்வுக்கான யோகா

யோகா பெண்களின் உடல் மற்றும் மன ஆரோக்கியத்திற்கு பல நன்மைகளை வழங்குகிறது.

## Benefits of Yoga

### Physical Benefits
- Improves flexibility and strength
- Enhances balance and posture
- Reduces pain and tension
- Supports reproductive health

### Mental Benefits
- Reduces stress and anxiety
- Improves mood and sleep
- Enhances mindfulness
- Promotes emotional balance

## Essential Poses

### Cat-Cow Pose
- Gentle spinal movement
- Relieves back tension
- Improves posture
- Safe during pregnancy

### Child's Pose
- Relaxes lower back
- Reduces stress
- Gentle hip opener
- Restorative and calming

### Butterfly Pose
- Opens hips and groin
- Relieves menstrual discomfort
- Improves circulation
- Gentle stretch

### Bridge Pose
- Strengthens back and glutes
- Opens chest and shoulders
- Improves posture
- Energizing

## Breathing Techniques

### Deep Breathing
- Calms nervous system
- Reduces stress
- Improves focus
- Practice daily

### Alternate Nostril Breathing
- Balances energy
- Reduces anxiety
- Improves concentration
- Traditional technique

## Practice Guidelines

### Frequency
- Start with 10-15 minutes daily
- Gradually increase to 30-60 minutes
- Listen to your body
- Be consistent

### Safety
- Warm up properly
- Don't force poses
- Modify as needed
- Consult doctor if pregnant

## Special Considerations

### During Periods
- Avoid inverted poses
- Focus on gentle stretches
- Listen to energy levels
- Restorative practices

### During Pregnancy
- Avoid deep twists
- Modify poses as needed
- Focus on breathing
- Prenatal yoga classes

## Creating a Routine

### Morning Practice
- Energizing poses
- Sun salutations
- Breathing exercises
- Sets positive tone

### Evening Practice
- Gentle stretches
- Relaxation poses
- Meditation
- Prepares for sleep

## When to Practice

- Choose consistent time
- Empty stomach preferred
- Quiet environment
- Comfortable clothing

யோகா சுய-கண்டுபிடிப்பு மற்றும் நல்வாழ்வின் பயணம்.''',
                'author': 'OvuMate யோகா குழு'
              };
            case 'si':
              return {
                'title': 'කාන්තා යහපැවැත්ම සඳහා යෝගා',
                'summary': 'කාන්තා සෞඛ්‍යයට විශේෂයෙන් ප්‍රයෝජනවත් යෝගා ඉරියව් සහ භාවිතයන්.',
                'content': '''# කාන්තා යහපැවැත්ම සඳහා යෝගා

යෝගා කාන්තාවන්ගේ ශාරීරික සහ මානසික සෞඛ්‍යය සඳහා බොහෝ ප්‍රතිලාභ ලබා දෙයි.

යෝගා ස්වයං-සොයාගැනීමේ සහ යහපැවැත්මේ ගමනකි.''',
                'author': 'OvuMate යෝගා කණ්ඩායම'
              };
            default:
              return {
                'title': 'Yoga for Women\'s Wellness',
                'summary': 'Yoga poses and practices specifically beneficial for women\'s health.',
                'content': '''# Yoga for Women's Wellness

Yoga offers numerous benefits for women's physical and mental health.

Yoga is a journey of self-discovery and wellness.''',
                'author': 'OvuMate Yoga Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_11',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.exercise,
        difficulty: ArticleDifficulty.beginner,
        readTime: 6,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['yoga', 'wellness', 'flexibility', 'mindfulness'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
      
      // Article 12
      ...(() {
        Map<String, dynamic> getContent(String lang) {
          switch (lang) {
            case 'ta':
              return {
                'title': 'தடுப்பு சுகாதார பரிசோதனைகள்',
                'summary': 'வெவ்வேறு வாழ்க்கை நிலைகளில் பெண்களுக்கான அத்தியாவசிய சுகாதார பரிசோதனைகள் மற்றும் பரிசோதனைகள்.',
                'content': '''# தடுப்பு சுகாதார பரிசோதனைகள்

வெவ்வேறு வாழ்க்கை நிலைகளில் பெண்களுக்கு தொடர்ந்து சுகாதார பரிசோதனைகள் முக்கியம்.

## Annual Check-ups

### Physical Examination
- Blood pressure measurement
- Weight and BMI assessment
- Heart and lung examination
- Skin examination

### Blood Tests
- Complete blood count
- Cholesterol levels
- Blood sugar levels
- Thyroid function

## Age-Specific Screenings

### Ages 21-29
- Pap smear every 3 years
- STI testing if sexually active
- Blood pressure annually
- Cholesterol check every 5 years

### Ages 30-39
- Pap smear every 3 years
- HPV testing every 5 years
- Blood pressure annually
- Cholesterol check every 5 years

### Ages 40-49
- Mammogram every 1-2 years
- Pap smear every 3 years
- Blood pressure annually
- Cholesterol check annually

### Ages 50+
- Mammogram annually
- Pap smear every 3 years
- Colonoscopy every 10 years
- Bone density test

## Special Considerations

### Family History
- Earlier screening if high risk
- Genetic testing if indicated
- More frequent monitoring
- Specialized screening protocols

### Pregnancy
- Regular prenatal care
- Gestational diabetes screening
- Group B strep testing
- Additional monitoring if high-risk

## Vaccinations

### Annual
- Influenza vaccine
- COVID-19 booster

### Every 10 Years
- Tdap (tetanus, diphtheria, pertussis)

### Age-Specific
- HPV vaccine (ages 9-26)
- Shingles vaccine (ages 50+)
- Pneumonia vaccine (ages 65+)

## Self-Examinations

### Breast Self-Exam
- Monthly examination
- Know your normal
- Report changes promptly
- Not a substitute for mammograms

### Skin Self-Exam
- Monthly full-body check
- Look for new or changing moles
- Use ABCDE rule
- Report suspicious changes

## Preparation for Appointments

### Before Visit
- List current medications
- Note symptoms or concerns
- Bring previous test results
- Prepare questions

### During Visit
- Ask questions
- Take notes
- Understand recommendations
- Schedule follow-ups

## When to Seek Immediate Care

- New or severe symptoms
- Unusual bleeding
- Persistent pain
- Sudden changes

தடுப்பு பராமரிப்பு உங்கள் நீண்ட கால ஆரோக்கியத்தில் முதலீடாகும்.''',
                'author': 'OvuMate மருத்துவ குழு'
              };
            case 'si':
              return {
                'title': 'ප්‍රතිරෝධාත්මක සෞඛ්‍ය පරීක්ෂණ',
                'summary': 'විවිධ ජීවන අවධීන්හි කාන්තාවන් සඳහා අත්‍යවශ්‍ය සෞඛ්‍ය පරීක්ෂණ සහ පරීක්ෂාවන්.',
                'content': '''# ප්‍රතිරෝධාත්මක සෞඛ්‍ය පරීක්ෂණ

විවිධ ජීවන අවධීන්හි කාන්තාවන් සඳහා නිත්‍ය සෞඛ්‍ය පරීක්ෂණ වැදගත්ය.

ප්‍රතිරෝධාත්මක රැකවරණය ඔබේ දීර්ඝ කාලීන සෞඛ්‍යයට ආයෝජනයකි.''',
                'author': 'OvuMate වෛද්‍ය කණ්ඩායම'
              };
            default:
              return {
                'title': 'Preventive Health Screenings',
                'summary': 'Essential health screenings and check-ups for women at different life stages.',
                'content': '''# Preventive Health Screenings

Regular health screenings are crucial for early detection and prevention of health issues.

Preventive care is an investment in your long-term health.''',
                'author': 'OvuMate Medical Team'
              };
          }
        }
        final content = getContent(languageCode);
        return [WellnessArticle(
          id: 'default_12',
          title: content['title'] as String,
          summary: content['summary'] as String,
          content: content['content'] as String,
        category: ArticleCategory.medical,
        difficulty: ArticleDifficulty.intermediate,
        readTime: 7,
        imageUrl: 'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop&crop=center',
        tags: ['preventive care', 'screenings', 'vaccinations', 'health check-ups'],
          author: content['author'] as String,
        publishedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFeatured: false,
        )];
      })(),
    ];
  }
  
  /// Initialize articles (fetch if needed, otherwise use cached)
  static Future<List<WellnessArticle>> initializeArticles() async {
    final currentLang = await _getCurrentLanguage();
    if (await shouldUpdateArticles()) {
      return await fetchLatestArticles();
    } else {
      return await _getCachedArticles();
    }
  }
  
  /// Force refresh articles with current language
  static Future<List<WellnessArticle>> refreshArticlesWithLanguage() async {
    return await fetchLatestArticles();
  }
  
  /// Force refresh articles
  static Future<List<WellnessArticle>> refreshArticles() async {
    return await fetchLatestArticles();
  }
  
  /// Clear cached articles
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedArticlesKey);
    await prefs.remove(_lastUpdateKey);
  }
  
  /// Get personalized article recommendations based on user profile
  static List<WellnessArticle> getPersonalizedRecommendations(
    List<WellnessArticle> articles,
    Map<String, dynamic> userProfile, {
    int limit = 10,
  }) {
    final List<WellnessArticle> recommendations = [];
    final Set<String> addedIds = {};
    
    // User preferences from profile
    final age = userProfile['age'] as int? ?? 25;
    final interests = userProfile['interests'] as List<String>? ?? [];
    final healthConditions = userProfile['health_conditions'] as List<String>? ?? [];
    final cycleLength = userProfile['cycle_length'] as int? ?? 28;
    final lastPeriod = userProfile['last_period'] as DateTime?;
    
    // Priority scoring for articles
    final scoredArticles = articles.map((article) {
      double score = 0.0;
      
      // Age-based relevance
      if (age < 25) {
        if (article.tags.any((tag) => ['young', 'teen', 'adolescent', 'first', 'beginner'].contains(tag.toLowerCase()))) {
          score += 2.0;
        }
      } else if (age > 35) {
        if (article.tags.any((tag) => ['mature', 'advanced', 'pregnancy', 'fertility'].contains(tag.toLowerCase()))) {
          score += 2.0;
        }
      }
      
      // Interest-based scoring
      for (final interest in interests) {
        if (article.tags.any((tag) => tag.toLowerCase().contains(interest.toLowerCase()))) {
          score += 3.0;
        }
        if (article.title.toLowerCase().contains(interest.toLowerCase())) {
          score += 2.0;
        }
        if (article.content.toLowerCase().contains(interest.toLowerCase())) {
          score += 1.0;
        }
      }
      
      // Health condition relevance
      for (final condition in healthConditions) {
        if (article.tags.any((tag) => tag.toLowerCase().contains(condition.toLowerCase()))) {
          score += 4.0;
        }
        if (article.title.toLowerCase().contains(condition.toLowerCase())) {
          score += 3.0;
        }
      }
      
      // Cycle-based recommendations
      if (lastPeriod != null) {
        final daysSinceLastPeriod = DateTime.now().difference(lastPeriod).inDays;
        final cyclePosition = daysSinceLastPeriod % cycleLength;
        
        // Follicular phase (days 1-13)
        if (cyclePosition <= 13) {
          if (article.tags.any((tag) => ['energy', 'exercise', 'nutrition'].contains(tag.toLowerCase()))) {
            score += 1.5;
          }
        }
        // Ovulation phase (days 14-16)
        else if (cyclePosition <= 16) {
          if (article.tags.any((tag) => ['fertility', 'ovulation', 'conception'].contains(tag.toLowerCase()))) {
            score += 2.0;
          }
        }
        // Luteal phase (days 17-28)
        else {
          if (article.tags.any((tag) => ['pms', 'mood', 'cramps', 'period pain'].contains(tag.toLowerCase()))) {
            score += 1.5;
          }
        }
      }
      
      // Category diversity bonus
      if (article.category == ArticleCategory.menstrualHealth) {
        score += 1.0; // Always relevant for women's health app
      }
      
      // Recency bonus (newer articles get higher score)
      final daysSincePublished = DateTime.now().difference(article.publishedAt).inDays;
      if (daysSincePublished <= 7) {
        score += 1.0;
      } else if (daysSincePublished <= 30) {
        score += 0.5;
      }
      
      // Featured articles bonus
      if (article.isFeatured) {
        score += 0.5;
      }
      
      return MapEntry(article, score);
    }).toList();
    
    // Sort by score and select top recommendations
    scoredArticles.sort((a, b) => b.value.compareTo(a.value));
    
    // Ensure category diversity
    final categoryCount = <ArticleCategory, int>{};
    
    for (final entry in scoredArticles) {
      final article = entry.key;
      
      if (addedIds.contains(article.id)) continue;
      if (recommendations.length >= limit) break;
      
      // Limit articles per category for diversity
      final categoryLimit = (limit / ArticleCategory.values.length).ceil();
      final currentCategoryCount = categoryCount[article.category] ?? 0;
      
      if (currentCategoryCount < categoryLimit) {
        recommendations.add(article);
        addedIds.add(article.id);
        categoryCount[article.category] = currentCategoryCount + 1;
      }
    }
    
    // If we don't have enough recommendations, fill with highest scored remaining articles
    if (recommendations.length < limit) {
      for (final entry in scoredArticles) {
        final article = entry.key;
        
        if (addedIds.contains(article.id)) continue;
        if (recommendations.length >= limit) break;
        
        recommendations.add(article);
        addedIds.add(article.id);
      }
    }
    
    return recommendations;
  }
  
  /// Get trending articles based on engagement metrics
  static List<WellnessArticle> getTrendingArticles(
    List<WellnessArticle> articles, {
    int limit = 5,
  }) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // Filter recent articles and score them
    final recentArticles = articles
        .where((article) => article.publishedAt.isAfter(sevenDaysAgo))
        .toList();
    
    // Score articles based on engagement (if available) and content quality
    final scoredArticles = recentArticles.map((article) {
      double score = 0.0;
      
      // View count score (if available)
      score += (article.viewCount * 0.1);
      
      // Rating score
      score += (article.rating * 2.0);
      
      // Recent publication bonus
      final daysSincePublished = now.difference(article.publishedAt).inDays;
      score += (7 - daysSincePublished) * 0.5;
      
      // Content length score (longer articles might be more comprehensive)
      final contentLength = article.content.length;
      if (contentLength > 1000) {
        score += 1.0;
      }
      
      // Featured articles bonus
      if (article.isFeatured) {
        score += 2.0;
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
  
  /// Get articles by category with smart filtering
  static List<WellnessArticle> getArticlesByCategory(
    List<WellnessArticle> articles,
    ArticleCategory category, {
    int limit = 20,
  }) {
    return articles
        .where((article) => article.category == category)
        .take(limit)
        .toList();
  }
  
  /// Search articles with smart matching
  static List<WellnessArticle> searchArticles(
    List<WellnessArticle> articles,
    String query, {
    int limit = 50,
  }) {
    if (query.isEmpty) return articles.take(limit).toList();
    
    final queryLower = query.toLowerCase().trim();
    final queryWords = queryLower.split(' ').where((word) => word.length > 2).toList();
    
    final scoredArticles = articles.map((article) {
      double score = 0.0;
      
      final titleLower = article.title.toLowerCase();
      final excerptLower = article.summary.toLowerCase();
      final contentLower = article.content.toLowerCase();
      final tagsLower = article.tags.map((tag) => tag.toLowerCase()).toList();
      
      // Exact phrase matches (highest priority)
      if (titleLower.contains(queryLower)) score += 10.0;
      if (excerptLower.contains(queryLower)) score += 5.0;
      if (contentLower.contains(queryLower)) score += 2.0;
      
      // Individual word matches
      for (final word in queryWords) {
        if (titleLower.contains(word)) score += 3.0;
        if (excerptLower.contains(word)) score += 2.0;
        if (contentLower.contains(word)) score += 1.0;
        if (tagsLower.any((tag) => tag.contains(word))) score += 2.0;
      }
      
      // Author name matches
      if (article.author.toLowerCase().contains(queryLower)) {
        score += 3.0;
      }
      
      return MapEntry(article, score);
    }).where((entry) => entry.value > 0).toList();
    
    // Sort by relevance score
    scoredArticles.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredArticles
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
}
