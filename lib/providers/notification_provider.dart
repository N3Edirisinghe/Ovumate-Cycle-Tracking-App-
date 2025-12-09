import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:intl/intl.dart';
import 'package:ovumate/services/article_service.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationProvider extends ChangeNotifier {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool _timezoneInitialized = false;

  bool _notificationsEnabled = true; // Enabled by default
  List<PendingNotificationRequest> _pendingNotifications = [];

  static const List<AndroidNotificationChannel> _androidChannels = [
    AndroidNotificationChannel(
      'period_reminders',
      'Period Reminders',
      description: 'Reminders for period tracking',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'ovulation_reminders',
      'Ovulation Reminders',
      description: 'Reminders for ovulation tracking',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'medication_reminders',
      'Medication Reminders',
      description: 'Reminders for medication',
      importance: Importance.high,
    ),
    AndroidNotificationChannel(
      'wellness_reminders',
      'Wellness Reminders',
      description: 'Reminders for wellness activities',
      importance: Importance.low,
    ),
    AndroidNotificationChannel(
      'immediate_notifications',
      'Immediate Notifications',
      description: 'Immediate notifications',
      importance: Importance.high,
    ),
  ];

  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  List<PendingNotificationRequest> get pendingNotifications => _pendingNotifications;
  List<AndroidNotificationChannel> get notificationChannels => _androidChannels;

  NotificationProvider() {
    _loadNotificationSettings();
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Load enabled state, default to true if not set
      _notificationsEnabled = prefs.getBool(Constants.notificationsKey) ?? true;
      debugPrint('📱 Loaded notification settings: enabled=$_notificationsEnabled');
    } catch (e) {
      debugPrint('⚠️ Failed to load notification settings: $e');
      // Keep default value (true)
    }
  }

  // Save notification settings to SharedPreferences
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(Constants.notificationsKey, _notificationsEnabled);
      debugPrint('💾 Saved notification settings: enabled=$_notificationsEnabled');
    } catch (e) {
      debugPrint('⚠️ Failed to save notification settings: $e');
    }
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
    await _createNotificationChannels();

    _isInitialized = true;
  }

  static Future<void> _configureLocalTimeZone() async {
    if (_timezoneInitialized) return;

    try {
      tz_data.initializeTimeZones();
      String timeZoneName = 'UTC';
      try {
        timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
      } catch (e) {
        debugPrint('Failed to get local timezone, defaulting to UTC: $e');
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (e) {
        debugPrint('Failed to apply timezone ($timeZoneName). Falling back to UTC: $e');
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Timezone data init failed. Falling back to UTC: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    _timezoneInitialized = true;
  }

  static Future<void> _createNotificationChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      for (final channel in _androidChannels) {
        await androidImplementation.createNotificationChannel(channel);
      }
    }
  }

  static Future<void> _requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(alert: true, badge: true, sound: true);

    final macImplementation = _notifications
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    await macImplementation?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> schedulePeriodReminder({
    required DateTime date,
    required String title,
    String? body,
  }) async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'period_reminders',
        'Period Reminders',
        channelDescription: 'Reminders for period tracking',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(Constants.periodColor),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        Constants.periodReminderId,
        title,
        body ?? 'Time to log your period',
        tz.TZDateTime.from(date, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'period_reminder',
      );

      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to schedule period reminder: $e');
    }
  }

  Future<void> scheduleOvulationReminder({
    required DateTime date,
    required String title,
    String? body,
  }) async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'ovulation_reminders',
        'Ovulation Reminders',
        channelDescription: 'Reminders for ovulation tracking',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(Constants.ovulationColor),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        Constants.ovulationReminderId,
        title,
        body ?? 'Ovulation window approaching',
        tz.TZDateTime.from(date, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'ovulation_reminder',
      );

      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to schedule ovulation reminder: $e');
    }
  }

  Future<void> scheduleMedicationReminder({
    required DateTime date,
    required String title,
    String? body,
    String? medicationName,
  }) async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'medication_reminders',
        'Medication Reminders',
        channelDescription: 'Reminders for medication',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(Constants.warningColor),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId =
          Constants.medicationReminderId + (medicationName?.hashCode ?? 0);

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body ?? 'Time to take your medication',
        tz.TZDateTime.from(date, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'medication_reminder:$medicationName',
      );

      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to schedule medication reminder: $e');
    }
  }

  Future<void> scheduleWellnessReminder({
    required DateTime date,
    required String title,
    String? body,
    String? category,
  }) async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'wellness_reminders',
        'Wellness Reminders',
        channelDescription: 'Reminders for wellness activities',
        importance: Importance.low,
        priority: Priority.low,
        color: Color(Constants.successColor),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = Constants.wellnessReminderId + (category?.hashCode ?? 0);

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body ?? 'Time for your wellness activity',
        tz.TZDateTime.from(date, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'wellness_reminder:$category',
      );

      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to schedule wellness reminder: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    await NotificationProvider.initialize();

    try {
      await _notifications.cancel(id);
      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cancel notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await NotificationProvider.initialize();

    try {
      await _notifications.cancelAll();
      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  Future<void> loadPendingNotifications() async {
    await NotificationProvider.initialize();

    try {
      _pendingNotifications = await _notifications.pendingNotificationRequests();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load pending notifications: $e');
    }
  }

  Future<void> _loadPendingNotifications() async {
    try {
      _pendingNotifications = await _notifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Failed to load pending notifications: $e');
    }
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;

    if (!_notificationsEnabled) {
      await cancelAllNotifications();
    } else {
      // If enabling, request permissions again to ensure they're granted
      await requestPermissions();
    }

    await _saveNotificationSettings();
    notifyListeners();
  }

  Future<void> requestPermissions() async {
    await NotificationProvider.initialize();
    await _requestPermissions();
    await loadPendingNotifications();
    
    // After requesting permissions, ensure notifications are enabled
    if (!_notificationsEnabled) {
      _notificationsEnabled = true;
      await _saveNotificationSettings();
      notifyListeners();
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'immediate_notifications',
        'Immediate Notifications',
        channelDescription: 'Immediate notifications',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(Constants.primaryColor),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );

      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to show immediate notification: $e');
    }
  }

  Future<void> createSampleNotifications() async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      await cancelAllNotifications();

      final now = DateTime.now();

      await schedulePeriodReminder(
        date: now.add(const Duration(minutes: 1)),
        title: 'Period Reminder',
        body: 'Your period is expected to start in 2 days. Don\'t forget to track it!',
      );

      await scheduleOvulationReminder(
        date: now.add(const Duration(minutes: 2)),
        title: 'Ovulation Window',
        body: 'You\'re in your fertile window. Track your symptoms for better predictions.',
      );

      await scheduleWellnessReminder(
        date: now.add(const Duration(minutes: 3)),
        title: 'Wellness Check-in',
        body: 'Time for your daily wellness activity. How are you feeling today?',
        category: 'daily_checkin',
      );

      debugPrint('Created 3 sample notifications');
    } catch (e) {
      debugPrint('Failed to create sample notifications: $e');
    }
  }

  bool isNotificationScheduled(int id) {
    return _pendingNotifications.any((notification) => notification.id == id);
  }

  int get notificationCount => _pendingNotifications.length;

  Future<void> scheduleNextCycleDateNotification({
    required DateTime nextCycleDate,
    String? title,
    String? body,
  }) async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      await _notifications.cancel(Constants.nextCycleDateId);

      final notificationDate = DateTime(
        nextCycleDate.year,
        nextCycleDate.month,
        nextCycleDate.day,
        9,
      );

      if (notificationDate.isAfter(DateTime.now())) {
        const androidDetails = AndroidNotificationDetails(
          'period_reminders',
          'Period Reminders',
          channelDescription: 'Reminders for period tracking',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(Constants.periodColor),
          enableVibration: true,
          playSound: true,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final formattedDate = DateFormat.yMMMMd().format(nextCycleDate);
        final notificationBody = body ??
            'Your next period is predicted for $formattedDate based on your recent entries.';

        await _notifications.zonedSchedule(
          Constants.nextCycleDateId,
          title ?? 'Next Period Reminder',
          notificationBody,
          tz.TZDateTime.from(notificationDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'next_cycle_date',
        );

        await _loadPendingNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to schedule next cycle date notification: $e');
    }
  }

  Future<void> scheduleSafePeriodNotification({
    required DateTime safePeriodStart,
    String? title,
    String? body,
  }) async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      await _notifications.cancel(Constants.safePeriodId);

      final notificationDate = DateTime(
        safePeriodStart.year,
        safePeriodStart.month,
        safePeriodStart.day,
        9,
      );

      if (notificationDate.isAfter(DateTime.now())) {
        const androidDetails = AndroidNotificationDetails(
          'ovulation_reminders',
          'Ovulation Reminders',
          channelDescription: 'Reminders for ovulation tracking',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(Constants.ovulationColor),
          enableVibration: true,
          playSound: true,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final formattedDate = DateFormat.yMMMMd().format(safePeriodStart);
        final notificationBody = body ??
            'Your predicted safe period begins on $formattedDate. Log your wellness details to keep insights accurate.';

        await _notifications.zonedSchedule(
          Constants.safePeriodId,
          title ?? 'Safe Period Started',
          notificationBody,
          tz.TZDateTime.from(notificationDate, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'safe_period',
        );

        await _loadPendingNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to schedule safe period notification: $e');
    }
  }

  Future<void> checkAndNotifyNewArticles() async {
    await NotificationProvider.initialize();
    if (!_notificationsEnabled) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastArticleCount = prefs.getInt('last_article_count') ?? 0;

      final articles = await ArticleService.fetchLatestArticles();
      final currentArticleCount = articles.length;

      if (currentArticleCount > lastArticleCount && lastArticleCount > 0) {
        final newArticleCount = currentArticleCount - lastArticleCount;

        const androidDetails = AndroidNotificationDetails(
          'wellness_reminders',
          'Wellness Reminders',
          channelDescription: 'Reminders for wellness activities',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(Constants.successColor),
          enableVibration: true,
          playSound: true,
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          Constants.newArticleId,
          'New Articles Available',
          '$newArticleCount new health article${newArticleCount > 1 ? 's' : ''} ${newArticleCount > 1 ? 'are' : 'is'} available. Check them out!',
          details,
          payload: 'new_articles',
        );
      }

      await prefs.setString('last_article_check', DateTime.now().toIso8601String());
      await prefs.setInt('last_article_count', currentArticleCount);

      await _loadPendingNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to check and notify new articles: $e');
    }
  }
}



