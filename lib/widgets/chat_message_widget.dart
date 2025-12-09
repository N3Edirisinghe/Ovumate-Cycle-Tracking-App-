import 'package:flutter/material.dart';
import 'package:ovumate/models/chat_message.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:ovumate/utils/theme.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final Function(String)? onQuickReply;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onQuickReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isUserMessage) const Spacer(),
          
          if (!message.isUserMessage)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryPink, AppTheme.secondaryPurple],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          
          if (!message.isUserMessage) const SizedBox(width: 12),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: message.isUserMessage
                    ? LinearGradient(
                        colors: [AppTheme.primaryPink, AppTheme.secondaryPurple],
                      )
                    : LinearGradient(
                        colors: [Colors.white, AppTheme.surfaceElevated],
                      ),
                borderRadius: BorderRadius.circular(24).copyWith(
                  bottomLeft: message.isUserMessage
                      ? const Radius.circular(24)
                      : const Radius.circular(6),
                  bottomRight: !message.isUserMessage
                      ? const Radius.circular(24)
                      : const Radius.circular(6),
                ),
                border: Border.all(
                  color: message.isUserMessage
                      ? Colors.transparent
                      : AppTheme.primaryPink.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUserMessage
                        ? AppTheme.primaryPink.withOpacity(0.2)
                        : AppTheme.primaryPink.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUserMessage 
                          ? Colors.white 
                          : AppTheme.textPrimaryLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      height: 1.5,
                    ),
                  ),
                  
                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      message.timeDisplay,
                      style: TextStyle(
                        color: message.isUserMessage
                            ? Colors.white.withOpacity(0.8)
                            : AppTheme.textSecondaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  
                  // Quick replies
                  if (message.hasQuickReplies && !message.isUserMessage) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: message.quickReplies!.map((reply) {
                        return GestureDetector(
                          onTap: () => onQuickReply?.call(reply),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryPink.withOpacity(0.1),
                                  AppTheme.secondaryPurple.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.primaryPink.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryPink.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              reply,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryPink,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // Suggestions
                  if (message.hasSuggestions && !message.isUserMessage) ...[
                    const SizedBox(height: 16),
                    Text(
                      'You might also want to know:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: message.suggestions!.map((suggestion) {
                        return GestureDetector(
                          onTap: () => onQuickReply?.call(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.borderLight,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              suggestion,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (message.isUserMessage) const SizedBox(width: 12),
          
          if (message.isUserMessage)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
















