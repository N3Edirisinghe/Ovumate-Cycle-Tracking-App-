import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:ovumate/models/cycle_entry.dart';

class WhatsAppShare {
  static const String _whatsappUrl = 'https://wa.me/';
  
  /// Share cycle summary to WhatsApp
  static Future<bool> shareCycleSummary({
    required DateTime nextPeriodDate,
    required DateTime? nextOvulationDate,
    required int cycleLength,
    required int periodLength,
    String? partnerPhone,
  }) async {
    final message = _formatCycleSummary(
      nextPeriodDate: nextPeriodDate,
      nextOvulationDate: nextOvulationDate,
      cycleLength: cycleLength,
      periodLength: periodLength,
    );
    
    return _shareToWhatsApp(message, partnerPhone);
  }
  
  /// Share specific cycle entry to WhatsApp
  static Future<bool> shareCycleEntry({
    required CycleEntry entry,
    String? partnerPhone,
  }) async {
    final message = _formatCycleEntry(entry);
    return _shareToWhatsApp(message, partnerPhone);
  }
  
  /// Share lifestyle data to WhatsApp
  static Future<bool> shareLifestyleData({
    required int sleepHours,
    required int waterIntake,
    required String mood,
    required List<String> activities,
    required int stressLevel,
    String? partnerPhone,
  }) async {
    final message = _formatLifestyleData(
      sleepHours: sleepHours,
      waterIntake: waterIntake,
      mood: mood,
      activities: activities,
      stressLevel: stressLevel,
    );
    
    return _shareToWhatsApp(message, partnerPhone);
  }
  
  /// Share ovulation reminder to WhatsApp
  static Future<bool> shareOvulationReminder({
    required DateTime ovulationDate,
    required DateTime fertileWindowStart,
    required DateTime fertileWindowEnd,
    String? partnerPhone,
  }) async {
    final message = _formatOvulationReminder(
      ovulationDate: ovulationDate,
      fertileWindowStart: fertileWindowStart,
      fertileWindowEnd: fertileWindowEnd,
    );
    
    return _shareToWhatsApp(message, partnerPhone);
  }
  
  /// Share period reminder to WhatsApp
  static Future<bool> sharePeriodReminder({
    required DateTime periodStartDate,
    required int periodLength,
    required List<String> symptoms,
    String? partnerPhone,
  }) async {
    final message = _formatPeriodReminder(
      periodStartDate: periodStartDate,
      periodLength: periodLength,
      symptoms: symptoms,
    );
    
    return _shareToWhatsApp(message, partnerPhone);
  }
  
  /// Share custom message to WhatsApp
  static Future<bool> shareCustomMessage({
    required String message,
    String? partnerPhone,
  }) async {
    return _shareToWhatsApp(message, partnerPhone);
  }
  
  /// Share message to specific contact via WhatsApp
  static Future<bool> shareToContact({
    required String phoneNumber,
    required String message,
  }) async {
    // Clean phone number (remove spaces, dashes, etc.)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Add country code if not present (assuming +94 for Sri Lanka)
    String formattedPhone = cleanPhone;
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        formattedPhone = '+94${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('94')) {
        formattedPhone = '+$cleanPhone';
      } else {
        formattedPhone = '+94$cleanPhone';
      }
    }
    
    // Create WhatsApp URL
    final whatsappUrl = '$_whatsappUrl${formattedPhone}?text=${Uri.encodeComponent(message)}';
    
    try {
      final uri = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      print('Error launching WhatsApp: $e');
      return false;
    }
  }
  
  /// Format cycle summary for sharing
  static String _formatCycleSummary({
    required DateTime nextPeriodDate,
    required DateTime? nextOvulationDate,
    required int cycleLength,
    required int periodLength,
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    final daysUntilPeriod = nextPeriodDate.difference(DateTime.now()).inDays;
    
    String message = '🩸 *Cycle Update*\n\n';
    message += '📅 *Next Period:* ${dateFormat.format(nextPeriodDate)}\n';
    message += '⏰ *Days Away:* $daysUntilPeriod days\n';
    message += '🔄 *Cycle Length:* $cycleLength days\n';
    message += '🩸 *Period Length:* $periodLength days\n';
    
    if (nextOvulationDate != null) {
      final daysUntilOvulation = nextOvulationDate.difference(DateTime.now()).inDays;
      message += '🥚 *Next Ovulation:* ${dateFormat.format(nextOvulationDate)}\n';
      message += '⏰ *Days Away:* $daysUntilOvulation days\n';
    }
    
    message += '\n💝 *Shared via OvuMate*';
    return message;
  }
  
  /// Format cycle entry for sharing
  static String _formatCycleEntry(CycleEntry entry) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('h:mm a');
    
    String message = '📝 *Cycle Entry*\n\n';
    message += '📅 *Date:* ${dateFormat.format(entry.date)}\n';
    message += '⏰ *Time:* ${timeFormat.format(entry.date)}\n';
    message += '🔄 *Phase:* ${entry.phaseDisplayName}\n';
    
    if (entry.isPeriodDay) {
      message += '🩸 *Period Day:* Yes\n';
      if (entry.periodFlow != null) {
        message += '💧 *Flow:* ${entry.periodFlowDescription}\n';
      }
    }
    
    if (entry.symptoms.isNotEmpty) {
      message += '🤒 *Symptoms:* ${entry.symptoms.join(', ')}\n';
    }
    
    if (entry.mood != null) {
      message += '😊 *Mood:* ${entry.mood}\n';
    }
    
    if (entry.notes != null && entry.notes!.isNotEmpty) {
      message += '📝 *Notes:* ${entry.notes}\n';
    }
    
    // Add lifestyle data if available
    if (entry.hasLifestyleData) {
      message += '\n🌿 *Lifestyle Data:*\n';
      if (entry.sleepHours != null) {
        message += '😴 Sleep: ${entry.sleepHours}h\n';
      }
      if (entry.waterIntake != null) {
        message += '💧 Water: ${entry.waterIntake}ml\n';
      }
      if (entry.stressLevel != null) {
        message += '📊 Stress: ${entry.stressLevel}/10\n';
      }
      if (entry.activities.isNotEmpty) {
        message += '🏃 Activities: ${entry.activities.join(', ')}\n';
      }
    }
    
    message += '\n💝 *Shared via OvuMate*';
    return message;
  }
  
  /// Format lifestyle data for sharing
  static String _formatLifestyleData({
    required int sleepHours,
    required int waterIntake,
    required String mood,
    required List<String> activities,
    required int stressLevel,
  }) {
    String message = '🌿 *Daily Wellness Update*\n\n';
    message += '😴 *Sleep:* ${sleepHours}h\n';
    message += '💧 *Water:* ${waterIntake}ml\n';
    message += '😊 *Mood:* $mood\n';
    message += '📊 *Stress Level:* $stressLevel/10\n';
    
    if (activities.isNotEmpty) {
      message += '🏃 *Activities:* ${activities.join(', ')}\n';
    }
    
    message += '\n💝 *Shared via OvuMate*';
    return message;
  }
  
  /// Format ovulation reminder for sharing
  static String _formatOvulationReminder({
    required DateTime ovulationDate,
    required DateTime fertileWindowStart,
    required DateTime fertileWindowEnd,
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    
    String message = '🥚 *Ovulation Reminder*\n\n';
    message += '📅 *Ovulation Date:* ${dateFormat.format(ovulationDate)}\n';
    message += '🌱 *Fertile Window:* ${dateFormat.format(fertileWindowStart)} - ${dateFormat.format(fertileWindowEnd)}\n';
    message += '💡 *Best Time:* 2-3 days before ovulation\n';
    
    message += '\n💝 *Shared via OvuMate*';
    return message;
  }
  
  /// Format period reminder for sharing
  static String _formatPeriodReminder({
    required DateTime periodStartDate,
    required int periodLength,
    required List<String> symptoms,
  }) {
    final dateFormat = DateFormat('EEEE, MMMM d');
    
    String message = '🩸 *Period Reminder*\n\n';
    message += '📅 *Start Date:* ${dateFormat.format(periodStartDate)}\n';
    message += '⏰ *Expected Duration:* $periodLength days\n';
    
    if (symptoms.isNotEmpty) {
      message += '🤒 *Common Symptoms:* ${symptoms.join(', ')}\n';
    }
    
    message += '\n💝 *Shared via OvuMate*';
    return message;
  }
  
  /// Share message to WhatsApp
  static Future<bool> _shareToWhatsApp(String message, String? partnerPhone) async {
    try {
      String url;
      
      if (partnerPhone != null && partnerPhone.isNotEmpty) {
        // Remove any non-digit characters from phone number
        final cleanPhone = partnerPhone.replaceAll(RegExp(r'[^\d]'), '');
        url = '$_whatsappUrl$cleanPhone?text=${Uri.encodeComponent(message)}';
      } else {
        // Share to general WhatsApp
        url = '$_whatsappUrl?text=${Uri.encodeComponent(message)}';
      }
      
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return false;
      }
    } catch (e) {
      print('Error sharing to WhatsApp: $e');
      return false;
    }
  }
  
  /// Check if WhatsApp is available
  static Future<bool> isWhatsAppAvailable() async {
    try {
      final uri = Uri.parse('$_whatsappUrl');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }
}
