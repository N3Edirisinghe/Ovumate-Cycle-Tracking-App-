import 'package:flutter/material.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/responsive_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/models/chat_message.dart';
import 'package:ovumate/services/health_api_service.dart';


class HealthAIScreen extends StatefulWidget {
  const HealthAIScreen({super.key});

  @override
  State<HealthAIScreen> createState() => _HealthAIScreenState();
}

class _HealthAIScreenState extends State<HealthAIScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  String _currentLanguage = 'en'; // 'en' for English, 'si' for Sinhala


  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get current app language (safe to access context here)
    if (_messages.isEmpty) {
      _currentLanguage = context.locale.languageCode;
      _initializeChat();
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  void _initializeChat() {
    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: HealthAPIService.getGreeting(_currentLanguage),
        type: MessageType.text,
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
      ),
    );
  }



  void _sendMessage(String message) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;

    setState(() {
      // Add user message
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: trimmedMessage,
          type: MessageType.text,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
    });

    // Clear the input field immediately
    _messageController.clear();

    // Generate bot response asynchronously to avoid blocking UI
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // Generate bot response using Health API Service with current language
          final botResponse = HealthAPIService.getHealthResponse(trimmedMessage, _currentLanguage);
          _messages.add(botResponse);
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFF5F8),
              const Color(0xFFF5F0FF),
              const Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(),
                
                // Chat Content
                Expanded(
                  child: _buildChatTabContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildCustomAppBar() {
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, isMobile ? 12 : 16, isMobile ? 16 : 20, isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPink,
            AppTheme.secondaryPurple,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with logo and controls
          Row(
            children: [
              // OvuMate name with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'OvuMate',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Agent Online Status
              Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isMobile ? 6 : 7,
                      height: isMobile ? 6 : 7,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successGreen.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isMobile ? 4 : 5),
                    Text(
                      'health_ai.status.online'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: isMobile ? 8 : 12),
              
              // Profile Button
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              
              SizedBox(width: isMobile ? 8 : 12),
              
              // Enhanced language toggle
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPink.withOpacity(0.2),
                      AppTheme.secondaryPurple.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPink.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        // Cycle through all 3 languages: EN → SI → TA → EN
                        if (_currentLanguage == 'en') {
                          _currentLanguage = 'si';
                        } else if (_currentLanguage == 'si') {
                          _currentLanguage = 'ta';
                        } else {
                          _currentLanguage = 'en';
                        }
                        if (_messages.isNotEmpty) {
                          _messages[0] = ChatMessage(
                            id: _messages[0].id,
                            content: HealthAPIService.getGreeting(_currentLanguage),
                            type: _messages[0].type,
                            sender: _messages[0].sender,
                            timestamp: _messages[0].timestamp,
                          );
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        _currentLanguage == 'en' ? 'EN' : (_currentLanguage == 'si' ? 'සිං' : 'த'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Professional title section
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'health_ai.title'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'health_ai.subtitle'.tr(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTabContent() {
    return Column(
      children: [
        // Chat messages area
        Expanded(
          child: _buildChatContent(),
        ),
        
        // Quick Suggestions - Above input section
        _buildQuickSuggestions(),
        
        // Input Section
        _buildInputSection(),
      ],
    );
  }

  Widget _buildChatContent() {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
      child: _buildMessagesList(),
    );
  }

  Widget _buildAIStatusCard() {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI Icon - Smaller
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryPink,
                  AppTheme.secondaryPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
            ),
            child: Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: isMobile ? 16 : 18,
            ),
          ),
          
          SizedBox(width: isMobile ? 8 : 12),
          
          // AI Status Information - Very Compact
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'health_ai.status.title'.tr(),
                  style: TextStyle(
                    color: AppTheme.primaryPink,
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 2 : 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: isMobile ? 5 : 6,
                      height: isMobile ? 5 : 6,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: isMobile ? 4 : 5),
                    Text(
                      'health_ai.status.online'.tr(),
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: isMobile ? 9 : 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    final isMobile = ResponsiveLayout.isMobile(context);
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPink.withOpacity(0.15),
                    AppTheme.secondaryPurple.withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: AppTheme.primaryPink,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'health_ai.chat.empty.title'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'health_ai.chat.empty.subtitle'.tr(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _messages.length,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 8, vertical: 12),
      itemBuilder: (context, index) {
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI Avatar with professional styling
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryPink,
                    AppTheme.secondaryPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: isMobile ? 18 : 20,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 12),
          ],
          
          // Message Content
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * (isMobile ? 0.75 : 0.65),
              ),
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              decoration: BoxDecoration(
                gradient: isUser 
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryPink,
                          AppTheme.secondaryPurple,
                        ],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser 
                        ? AppTheme.primaryPink.withOpacity(0.25)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: isMobile ? 14 : 15,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  // Timestamp
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            SizedBox(width: isMobile ? 8 : 12),
            // User Avatar with professional styling
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentTeal,
                    AppTheme.primaryPink,
                  ],
                ),
                borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentTeal.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: isMobile ? 18 : 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'health_ai.chat.time.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return 'health_ai.chat.time.minutes_ago'.tr(args: ['${difference.inMinutes}']);
    } else if (difference.inHours < 24) {
      return 'health_ai.chat.time.hours_ago'.tr(args: ['${difference.inHours}']);
    } else {
      return 'health_ai.chat.time.days_ago'.tr(args: ['${difference.inDays}']);
    }
  }

  Widget _buildQuickSuggestions() {
    final suggestions = HealthAPIService.getSuggestions(_currentLanguage);
    final isMobile = ResponsiveLayout.isMobile(context);
    
    // Show only first 3 suggestions on mobile to save space
    final displaySuggestions = isMobile ? suggestions.take(3).toList() : suggestions.take(4).toList();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 2),
      padding: EdgeInsets.all(isMobile ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.surfaceElevated,
          ],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 4 : 5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryPink, AppTheme.secondaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 6 : 7),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.white,
                  size: isMobile ? 12 : 14,
                ),
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Text(
                'health_ai.chat.suggestions.title'.tr(),
                style: TextStyle(
                  color: const Color(0xFF1A252F),
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 6 : 8),
          Wrap(
            spacing: isMobile ? 4 : 6,
            runSpacing: isMobile ? 4 : 6,
            children: displaySuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _messageController.text = suggestion;
                  _sendMessage(suggestion);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 12, vertical: isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryPink.withOpacity(0.1),
                        AppTheme.secondaryPurple.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 14 : 16),
                    border: Border.all(
                      color: AppTheme.primaryPink.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppTheme.primaryPink,
                        size: isMobile ? 10 : 11,
                      ),
                      SizedBox(width: isMobile ? 4 : 5),
                      Flexible(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            color: AppTheme.primaryPink,
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }



  Widget _buildInputSection() {
    final isMobile = ResponsiveLayout.isMobile(context);
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 10 : 12, isMobile ? 6 : 8, isMobile ? 10 : 12, isMobile ? 8 : 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isMobile ? 20 : 24),
        ),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left margin for positioning
          SizedBox(width: isMobile ? 12 : 16),
          
          // Professional input field
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(isMobile ? 14 : 16, isMobile ? 8 : 10, isMobile ? 10 : 12, isMobile ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ],
                ),
                borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                border: Border.all(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                enabled: true,
                autofocus: false,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: 'health_ai.chat.input.placeholder'.tr(),
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 8 : 10),
                ),
                maxLines: null,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _sendMessage(value);
                  }
                },
              ),
            ),
          ),
          
          SizedBox(width: isMobile ? 8 : 12),
          
          // Professional send button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryPink,
                  AppTheme.secondaryPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPink.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
                onTap: () {
                  final message = _messageController.text.trim();
                  if (message.isNotEmpty) {
                    _sendMessage(message);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 12),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: isMobile ? 20 : 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
