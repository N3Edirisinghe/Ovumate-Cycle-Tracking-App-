import 'dart:convert';
import 'dart:math';
import 'package:ovumate/models/chat_message.dart';
import 'package:ovumate/models/wellness_article.dart';

/// AI-powered chatbot service for women's health questions
class ChatbotService {
  // Knowledge base for common questions
  static const Map<String, List<String>> _knowledgeBase = {
    'menstrual_cycle': [
      'The menstrual cycle typically lasts 21-35 days, with the average being 28 days.',
      'The cycle has four phases: menstrual, follicular, ovulation, and luteal.',
      'Ovulation usually occurs around day 14 of a 28-day cycle.',
      'Periods typically last 3-7 days with moderate to heavy flow.',
      'Irregular cycles can be caused by stress, diet, exercise, or medical conditions.',
    ],
    'period_pain': [
      'Period pain (dysmenorrhea) is common and usually normal.',
      'Mild to moderate cramps can be relieved with heat therapy, exercise, and over-the-counter pain relievers.',
      'Severe pain that interferes with daily activities should be evaluated by a healthcare provider.',
      'Regular exercise, especially yoga and stretching, can help reduce period pain.',
      'Some women find relief from herbal teas like chamomile, ginger, or peppermint.',
    ],
    'fertility': [
      'Fertility is highest during ovulation, typically around day 14 of a 28-day cycle.',
      'You can track ovulation through basal body temperature, cervical mucus changes, or ovulation predictor kits.',
      'Age affects fertility - peak fertility is typically in your 20s.',
      'Lifestyle factors like diet, exercise, and stress management can impact fertility.',
      'If trying to conceive for over a year, consider consulting a fertility specialist.',
    ],
    'pregnancy': [
      'Early pregnancy symptoms can include missed periods, breast tenderness, nausea, and fatigue.',
      'Prenatal care should begin as soon as you know you\'re pregnant.',
      'Important nutrients during pregnancy include folic acid, iron, calcium, and omega-3 fatty acids.',
      'Regular prenatal checkups help monitor both maternal and fetal health.',
      'Exercise during pregnancy is generally safe and beneficial, but consult your healthcare provider.',
    ],
    'nutrition': [
      'A balanced diet rich in fruits, vegetables, whole grains, and lean proteins supports overall health.',
      'Iron-rich foods are especially important during menstruation to prevent anemia.',
      'Calcium and vitamin D are crucial for bone health, especially as you age.',
      'Omega-3 fatty acids support heart and brain health.',
      'Staying hydrated is important for overall wellness and can help with period symptoms.',
    ],
    'mental_health': [
      'Hormonal changes during your cycle can affect mood and mental health.',
      'PMS symptoms can include mood swings, anxiety, and depression.',
      'Regular exercise, adequate sleep, and stress management can help with mental health.',
      'Don\'t hesitate to seek professional help if you\'re struggling with mental health.',
      'Support groups and talking with trusted friends can be very helpful.',
    ],
    'exercise': [
      'Exercise during your period can actually help reduce cramps and improve mood.',
      'Low-impact activities like walking, swimming, and yoga are good choices during menstruation.',
      'Listen to your body and reduce intensity if you feel tired or in pain.',
      'Regular exercise throughout your cycle can help regulate periods and reduce symptoms.',
      'Pelvic floor exercises can help with various women\'s health issues.',
    ],
    'general_health': [
      'Regular health checkups are important for preventive care.',
      'Screenings like Pap smears and mammograms are crucial for early detection.',
      'Vaccinations protect against serious diseases.',
      'Good sleep hygiene supports overall health and hormone regulation.',
      'Stress management techniques like meditation can improve overall wellness.',
    ],
  };

  // Common questions and their categories
  static const Map<String, String> _questionCategories = {
    'period': 'menstrual_cycle',
    'cycle': 'menstrual_cycle',
    'menstrual': 'menstrual_cycle',
    'cramps': 'period_pain',
    'pain': 'period_pain',
    'dysmenorrhea': 'period_pain',
    'fertility': 'fertility',
    'ovulation': 'fertility',
    'conceive': 'fertility',
    'pregnant': 'pregnancy',
    'pregnancy': 'pregnancy',
    'prenatal': 'pregnancy',
    'nutrition': 'nutrition',
    'diet': 'nutrition',
    'food': 'nutrition',
    'vitamins': 'nutrition',
    'mental': 'mental_health',
    'mood': 'mental_health',
    'anxiety': 'mental_health',
    'depression': 'mental_health',
    'pms': 'mental_health',
    'exercise': 'exercise',
    'workout': 'exercise',
    'fitness': 'exercise',
    'yoga': 'exercise',
    'health': 'general_health',
    'checkup': 'general_health',
    'screening': 'general_health',
    'vaccine': 'general_health',
  };

  // Greeting messages
  static const List<String> _greetings = [
    'Hello! I\'m here to help with your health questions. What would you like to know?',
    'Hi there! I\'m your health assistant. How can I help you today?',
    'Welcome! I\'m here to answer your questions about women\'s health and wellness.',
    'Hello! I\'m ready to help with any health-related questions you have.',
  ];

  // Follow-up questions to encourage conversation
  static const Map<String, List<String>> _followUpQuestions = {
    'menstrual_cycle': [
      'Would you like to know more about tracking your cycle?',
      'Are you experiencing any specific cycle-related issues?',
      'Would you like tips for managing irregular periods?',
    ],
    'period_pain': [
      'Are you looking for natural remedies for period pain?',
      'Would you like to know when to see a doctor about period pain?',
      'Are you interested in exercises that can help with cramps?',
    ],
    'fertility': [
      'Are you trying to conceive or just learning about fertility?',
      'Would you like to know more about ovulation tracking?',
      'Are you interested in lifestyle factors that affect fertility?',
    ],
    'pregnancy': [
      'Are you currently pregnant or planning to become pregnant?',
      'Would you like to know more about prenatal care?',
      'Are you interested in nutrition during pregnancy?',
    ],
  };

  /// Generate a response to user input
  static ChatMessage generateResponse(String userInput, List<ChatMessage> conversationHistory) {
    final input = userInput.toLowerCase().trim();
    
    // Check if it's a greeting
    if (_isGreeting(input)) {
      return _generateGreeting();
    }
    
    // Check if it's a goodbye
    if (_isGoodbye(input)) {
      return _generateGoodbye();
    }
    
    // Analyze the question and find relevant information
    final category = _categorizeQuestion(input);
    final answer = _generateAnswer(input, category);
    final followUp = _generateFollowUp(category);
    
    // Combine answer with follow-up
    String fullResponse = answer;
    if (followUp.isNotEmpty) {
      fullResponse += '\n\n$followUp';
    }
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: fullResponse,
      type: MessageType.text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }

  /// Check if input is a greeting
  static bool _isGreeting(String input) {
    final greetings = ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening'];
    return greetings.any((greeting) => input.contains(greeting));
  }

  /// Check if input is a goodbye
  static bool _isGoodbye(String input) {
    final goodbyes = ['bye', 'goodbye', 'see you', 'thank you', 'thanks', 'thank'];
    return goodbyes.any((goodbye) => input.contains(goodbye));
  }

  /// Generate a greeting response
  static ChatMessage _generateGreeting() {
    final random = Random();
    final greeting = _greetings[random.nextInt(_greetings.length)];
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: greeting,
      type: MessageType.text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }

  /// Generate a goodbye response
  static ChatMessage _generateGoodbye() {
    final responses = [
      'You\'re welcome! Feel free to ask if you have more questions.',
      'Happy to help! Take care and stay healthy!',
      'Anytime! Don\'t hesitate to reach out with more questions.',
      'Glad I could help! Stay well!',
    ];
    
    final random = Random();
    final response = responses[random.nextInt(responses.length)];
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      type: MessageType.text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }

  /// Categorize the user's question
  static String _categorizeQuestion(String input) {
    // Check for exact matches first
    for (final entry in _questionCategories.entries) {
      if (input.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Check for related terms
    if (input.contains('symptom') || input.contains('problem') || input.contains('issue')) {
      return 'general_health';
    }
    
    if (input.contains('when') || input.contains('how often') || input.contains('regular')) {
      return 'menstrual_cycle';
    }
    
    if (input.contains('what') || input.contains('why') || input.contains('how')) {
      return 'general_health';
    }
    
    // Default to general health
    return 'general_health';
  }

  /// Generate an answer based on the category
  static String _generateAnswer(String input, String category) {
    final knowledge = _knowledgeBase[category];
    if (knowledge == null || knowledge.isEmpty) {
      return 'I\'m here to help with your health questions. Could you please be more specific about what you\'d like to know?';
    }
    
    // Find the most relevant piece of information
    String bestAnswer = knowledge.first;
    int bestScore = 0;
    
    for (final info in knowledge) {
      final score = _calculateRelevanceScore(input, info);
      if (score > bestScore) {
        bestScore = score;
        bestAnswer = info;
      }
    }
    
    // If no good match found, provide a general answer
    if (bestScore < 2) {
      return knowledge[Random().nextInt(knowledge.length)];
    }
    
    return bestAnswer;
  }

  /// Calculate relevance score between user input and knowledge
  static int _calculateRelevanceScore(String input, String knowledge) {
    final inputWords = input.split(' ').where((word) => word.length > 2).toSet();
    final knowledgeWords = knowledge.toLowerCase().split(' ').where((word) => word.length > 2).toSet();
    
    int score = 0;
    for (final word in inputWords) {
      if (knowledgeWords.contains(word.toLowerCase())) {
        score++;
      }
    }
    
    return score;
  }

  /// Generate a follow-up question
  static String _generateFollowUp(String category) {
    final followUps = _followUpQuestions[category];
    if (followUps == null || followUps.isEmpty) {
      return '';
    }
    
    final random = Random();
    return followUps[random.nextInt(followUps.length)];
  }

  /// Get quick action suggestions
  static List<String> getQuickActions() {
    return [
      'Tell me about my menstrual cycle',
      'How to manage period pain?',
      'Fertility and ovulation tips',
      'Pregnancy and prenatal care',
      'Nutrition for women\'s health',
      'Mental health during periods',
      'Exercise during menstruation',
      'General health checkups',
    ];
  }

  /// Get contextual suggestions based on conversation
  static List<String> getContextualSuggestions(List<ChatMessage> conversation) {
    if (conversation.isEmpty) {
      return getQuickActions();
    }
    
    // Analyze recent conversation to suggest relevant topics
    final recentMessages = conversation.take(3).toList();
    final suggestions = <String>[];
    
    for (final message in recentMessages) {
      if (message.sender != MessageSender.user) continue;
      
      final input = message.content.toLowerCase();
      
      if (input.contains('period') || input.contains('cycle')) {
        suggestions.addAll([
          'Track your cycle',
          'Manage period symptoms',
          'Irregular periods help',
        ]);
      }
      
      if (input.contains('pain') || input.contains('cramp')) {
        suggestions.addAll([
          'Natural pain relief',
          'Exercise for cramps',
          'When to see a doctor',
        ]);
      }
      
      if (input.contains('fertility') || input.contains('pregnant')) {
        suggestions.addAll([
          'Ovulation tracking',
          'Prenatal vitamins',
          'Fertility lifestyle tips',
        ]);
      }
      
      if (input.contains('nutrition') || input.contains('diet')) {
        suggestions.addAll([
          'Iron-rich foods',
          'Calcium sources',
          'Healthy eating tips',
        ]);
      }
    }
    
    // Remove duplicates and limit suggestions
    final uniqueSuggestions = suggestions.toSet().take(4).toList();
    
    // If no contextual suggestions, return general ones
    if (uniqueSuggestions.isEmpty) {
      return getQuickActions().take(4).toList();
    }
    
    return uniqueSuggestions;
  }

  /// Generate a comprehensive health summary
  static String generateHealthSummary(List<ChatMessage> conversation) {
    if (conversation.isEmpty) {
      return 'Start a conversation to get personalized health insights!';
    }
    
    final userMessages = conversation.where((msg) => msg.sender == MessageSender.user).toList();
    if (userMessages.isEmpty) {
      return 'I\'m here to help with your health questions!';
    }
    
    // Analyze conversation topics
    final topics = <String, int>{};
    for (final message in userMessages) {
      final category = _categorizeQuestion(message.content);
      topics[category] = (topics[category] ?? 0) + 1;
    }
    
    // Generate summary based on most discussed topics
    final mainTopic = topics.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final summary = _generateTopicSummary(mainTopic);
    
    return 'Based on our conversation, here\'s what I can tell you:\n\n$summary';
  }

  /// Generate summary for a specific topic
  static String _generateTopicSummary(String topic) {
    switch (topic) {
      case 'menstrual_cycle':
        return 'You\'ve been asking about menstrual cycles. Remember that cycles can vary from 21-35 days, and tracking your cycle can help identify patterns and potential issues.';
      
      case 'period_pain':
        return 'You\'ve been asking about period pain. While some discomfort is normal, severe pain that interferes with daily activities should be evaluated by a healthcare provider.';
      
      case 'fertility':
        return 'You\'ve been asking about fertility. Understanding your ovulation cycle and maintaining a healthy lifestyle can significantly impact your fertility journey.';
      
      case 'pregnancy':
        return 'You\'ve been asking about pregnancy. Early prenatal care and proper nutrition are crucial for both maternal and fetal health.';
      
      case 'nutrition':
        return 'You\'ve been asking about nutrition. A balanced diet rich in essential nutrients supports overall health and can help manage various health concerns.';
      
      case 'mental_health':
        return 'You\'ve been asking about mental health. Hormonal changes can affect mood, and it\'s important to practice self-care and seek help when needed.';
      
      case 'exercise':
        return 'You\'ve been asking about exercise. Regular physical activity can help regulate cycles, reduce symptoms, and improve overall wellness.';
      
      default:
        return 'You\'ve been asking about general health topics. Remember that regular checkups and a healthy lifestyle are key to maintaining good health.';
    }
  }

  /// Check if the service is available
  static bool get isAvailable => true;

  /// Get service status
  static Map<String, dynamic> getStatus() {
    return {
      'available': isAvailable,
      'knowledge_topics': _knowledgeBase.keys.toList(),
      'total_responses': _knowledgeBase.values.fold(0, (sum, list) => sum + list.length),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}
