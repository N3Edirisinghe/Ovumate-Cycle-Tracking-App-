import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'package:ovumate/utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'common.back'.tr(),
          color: Colors.white,
        ),
        title: Text(
          'notifications.title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return TextButton(
                onPressed: () {
                  _showClearAllDialog(context, notificationProvider);
                },
                child: Text(
                  'notifications.clear_all'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          final notifications = notificationProvider.pendingNotifications;
          
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }
          
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Notification count header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.borderLight,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        notifications.length == 1 ? 'notifications.count.single'.tr(args: ['${notifications.length}']) : 'notifications.count.multiple'.tr(args: ['${notifications.length}']),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Notifications list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationCard(
                        notification,
                        index,
                        notificationProvider,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: AppTheme.primaryPink,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'notifications.empty.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A252F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'notifications.empty.subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Color(0xFF5D6D7E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    PendingNotificationRequest notification,
    int index,
    NotificationProvider notificationProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _handleNotificationTap(notification, notificationProvider);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Notification icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification),
                    color: _getNotificationColor(notification),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Notification content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title ?? 'Notification',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A252F),
                        ),
                      ),
                      if (notification.body != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.body!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Color(0xFF5D6D7E),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textTertiaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatNotificationTime(notification),
                            style: TextStyle(
                              color: AppTheme.textTertiaryLight,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(notification).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getNotificationType(notification),
                              style: TextStyle(
                                color: _getNotificationColor(notification),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Action buttons
                Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        _handleNotificationTap(notification, notificationProvider);
                      },
                      icon: Icon(
                        Icons.visibility,
                        color: AppTheme.primaryPink,
                        size: 20,
                      ),
                      tooltip: 'notifications.actions.view'.tr(),
                    ),
                    IconButton(
                      onPressed: () {
                        _dismissNotification(notification, notificationProvider);
                      },
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textTertiaryLight,
                        size: 20,
                      ),
                      tooltip: 'notifications.actions.dismiss'.tr(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(PendingNotificationRequest notification) {
    final payload = notification.payload ?? '';
    if (payload.contains('period')) {
      return AppTheme.primaryPink;
    } else if (payload.contains('ovulation')) {
      return AppTheme.secondaryPurple;
    } else if (payload.contains('wellness')) {
      return AppTheme.successGreen;
    } else {
      return AppTheme.accentTeal;
    }
  }

  IconData _getNotificationIcon(PendingNotificationRequest notification) {
    final payload = notification.payload ?? '';
    if (payload.contains('period')) {
      return Icons.calendar_today;
    } else if (payload.contains('ovulation')) {
      return Icons.egg;
    } else if (payload.contains('wellness')) {
      return Icons.health_and_safety;
    } else {
      return Icons.notifications;
    }
  }

  String _getNotificationType(PendingNotificationRequest notification) {
    final payload = notification.payload ?? '';
    if (payload.contains('period')) {
      return 'notifications.types.period'.tr();
    } else if (payload.contains('ovulation')) {
      return 'notifications.types.ovulation'.tr();
    } else if (payload.contains('wellness')) {
      return 'notifications.types.wellness'.tr();
    } else {
      return 'notifications.types.general'.tr();
    }
  }

  String _formatNotificationTime(PendingNotificationRequest notification) {
    // This is a simplified version - in a real app you'd store the scheduled time
    return 'notifications.time.scheduled'.tr();
  }

  void _handleNotificationTap(
    PendingNotificationRequest notification,
    NotificationProvider notificationProvider,
  ) {
    // Handle notification tap based on payload
    final payload = notification.payload ?? '';
    
    if (payload.contains('period')) {
      // Navigate to cycle tracking
      Navigator.pop(context);
      // TODO: Navigate to cycle tracking screen
    } else if (payload.contains('ovulation')) {
      // Navigate to ovulation calculator
      Navigator.pop(context);
      // TODO: Navigate to ovulation calculator
    } else if (payload.contains('wellness')) {
      // Navigate to wellness screen
      Navigator.pop(context);
      // TODO: Navigate to wellness screen
    }
    
    // Mark as read by dismissing
    _dismissNotification(notification, notificationProvider);
  }

  void _dismissNotification(
    PendingNotificationRequest notification,
    NotificationProvider notificationProvider,
  ) {
    notificationProvider.cancelNotification(notification.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('notifications.messages.dismissed'.tr()),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    NotificationProvider notificationProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'notifications.clear_dialog.title'.tr(),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'notifications.clear_dialog.message'.tr(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'notifications.clear_dialog.cancel'.tr(),
                style: TextStyle(color: AppTheme.textTertiaryLight),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                notificationProvider.cancelAllNotifications();
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('notifications.messages.all_cleared'.tr()),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('notifications.clear_dialog.confirm'.tr()),
            ),
          ],
        );
      },
    );
  }
}
