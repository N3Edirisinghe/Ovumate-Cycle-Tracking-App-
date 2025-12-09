enum MessageType {
  text,
  image,
  quickReply,
  suggestion,
  system
}

enum MessageSender {
  user,
  bot,
  system
}

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageSender sender;
  final DateTime timestamp;
  final String? userId;
  final List<String>? quickReplies;
  final List<String>? suggestions;
  final String? imageUrl;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.userId,
    this.quickReplies,
    this.suggestions,
    this.imageUrl,
    this.isRead = false,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      sender: MessageSender.values.firstWhere(
        (e) => e.toString().split('.').last == json['sender'],
        orElse: () => MessageSender.user,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['user_id'],
      quickReplies: json['quick_replies'] != null 
          ? List<String>.from(json['quick_replies']) 
          : null,
      suggestions: json['suggestions'] != null 
          ? List<String>.from(json['suggestions']) 
          : null,
      imageUrl: json['image_url'],
      isRead: json['is_read'] ?? false,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'sender': sender.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'quick_replies': quickReplies,
      'suggestions': suggestions,
      'image_url': imageUrl,
      'is_read': isRead,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageSender? sender,
    DateTime? timestamp,
    String? userId,
    List<String>? quickReplies,
    List<String>? suggestions,
    String? imageUrl,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      quickReplies: quickReplies ?? this.quickReplies,
      suggestions: suggestions ?? this.suggestions,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isUserMessage => sender == MessageSender.user;
  bool get isBotMessage => sender == MessageSender.bot;
  bool get isSystemMessage => sender == MessageSender.system;

  String get timeDisplay {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get hasQuickReplies => quickReplies != null && quickReplies!.isNotEmpty;
  bool get hasSuggestions => suggestions != null && suggestions!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

