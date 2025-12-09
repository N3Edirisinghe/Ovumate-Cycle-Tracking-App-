import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'package:ovumate/services/supabase_service.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CycleProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  NotificationProvider? _notificationProvider;
  
  List<CycleEntry> _cycleEntries = [];
  List<CycleEntry> _currentMonthEntries = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Cycle predictions
  DateTime? _nextPeriodStart;
  DateTime? _nextOvulationDate;
  List<DateTime> _fertileWindow = [];
  CyclePhase _currentPhase = CyclePhase.unknown;
  
  // Statistics
  int _averageCycleLength = Constants.defaultCycleLength;
  int _averagePeriodLength = Constants.defaultPeriodLength;
  int _cyclesTracked = 0;

  // Getters
  List<CycleEntry> get cycleEntries => _cycleEntries;
  List<CycleEntry> get currentMonthEntries => _currentMonthEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get nextPeriodStart => _nextPeriodStart;
  DateTime? get nextOvulationDate => _nextOvulationDate;
  List<DateTime> get fertileWindow => _fertileWindow;
  CyclePhase get currentPhase => _currentPhase;
  int get averageCycleLength => _averageCycleLength;
  int get averagePeriodLength => _averagePeriodLength;
  int get cyclesTracked => _cyclesTracked;
  bool get isInitialized => true;

  // Attach notification provider for scheduling reminders
  void attachNotificationProvider(NotificationProvider provider) {
    if (_notificationProvider == provider) return;
    _notificationProvider = provider;
    unawaited(_syncNotifications());
  }

  // Initialize cycle data
  Future<void> initialize([String? userId]) async {
    try {
      _setLoading(true);
      
      final effectiveUserId = userId ?? _supabaseService.currentUserId ?? 'guest_user';
      
      // Try to load from Supabase first (if authenticated)
      if (_supabaseService.isAuthenticated && userId != null) {
        try {
          await _loadCycleEntriesFromSupabase(userId);
        } catch (e) {
          debugPrint('Failed to load from Supabase, falling back to local: $e');
          await _loadCycleEntriesFromStorage();
        }
      } else {
        // Fallback to local storage for guest users
        await _loadCycleEntriesFromStorage();
      }
      
      // Calculate statistics and predictions based on user data
      await _calculateStatistics();
      await _predictNextCycle();
      _determineCurrentPhase();
      await _syncNotifications();
    } catch (e) {
      debugPrint('Error initializing cycle provider: $e');
      _setError('Failed to initialize cycle data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load cycle entries from Supabase
  Future<void> _loadCycleEntriesFromSupabase(String userId) async {
    try {
      _cycleEntries = await _supabaseService.getCycleEntries(userId);
      _filterCurrentMonthEntries();
      debugPrint('Loaded ${_cycleEntries.length} entries from Supabase');
    } catch (e) {
      debugPrint('Error loading from Supabase: $e');
      rethrow;
    }
  }

  // Load cycle entries from local storage
  Future<void> _loadCycleEntriesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString('cycle_entries');
      
      if (entriesJson != null) {
        final List<dynamic> entriesList = json.decode(entriesJson);
        _cycleEntries = entriesList
            .map((entry) => CycleEntry.fromJson(entry as Map<String, dynamic>))
            .toList();
        
        _filterCurrentMonthEntries();
      }
    } catch (e) {
      debugPrint('Failed to load cycle entries: $e');
      _cycleEntries = [];
      _filterCurrentMonthEntries();
    }
  }

  // Save cycle entries to local storage
  Future<void> _saveCycleEntriesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = json.encode(_cycleEntries.map((e) => e.toJson()).toList());
      await prefs.setString('cycle_entries', entriesJson);
    } catch (e) {
      debugPrint('Failed to save cycle entries: $e');
    }
  }

  // Add new cycle entry
  Future<bool> addCycleEntry(CycleEntry entry) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Ensure entry has a unique ID and timestamps
      final now = DateTime.now();
      final entryToAdd = entry.id.isEmpty 
        ? CycleEntry(
            id: const Uuid().v4(),
            userId: entry.userId,
            date: entry.date,
            phase: entry.phase,
            isPeriodDay: entry.isPeriodDay,
            periodFlow: entry.periodFlow,
            symptoms: entry.symptoms,
            symptomSeverity: entry.symptomSeverity,
            notes: entry.notes,
            createdAt: now,
            updatedAt: now,
            sleepHours: entry.sleepHours,
            waterIntake: entry.waterIntake,
            stressLevel: entry.stressLevel,
            mood: entry.mood,
            activities: entry.activities,
            tookMedication: entry.tookMedication,
            medicationNotes: entry.medicationNotes,
          )
        : entry.copyWith(
            updatedAt: now,
          );
      
      // Try to save to Supabase first (if authenticated)
      if (_supabaseService.isAuthenticated && entry.userId != 'guest_user') {
        try {
          final savedEntry = await _supabaseService.addCycleEntry(entryToAdd);
          _cycleEntries.insert(0, savedEntry);
          debugPrint('Saved entry to Supabase: ${savedEntry.id}');
        } catch (e) {
          debugPrint('Failed to save to Supabase, saving locally: $e');
          _cycleEntries.insert(0, entryToAdd);
          await _saveCycleEntriesToStorage();
        }
      } else {
        // Save to local storage for guest users
        _cycleEntries.insert(0, entryToAdd);
        await _saveCycleEntriesToStorage();
      }
      
      _filterCurrentMonthEntries();
      
      // Recalculate based on new user data
      await _calculateStatistics();
      await _predictNextCycle();
      _determineCurrentPhase();
      await _syncNotifications();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding cycle entry: $e');
      _setError('Failed to add cycle entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update existing cycle entry
  Future<bool> updateCycleEntry(CycleEntry entry) async {
    try {
      _setLoading(true);
      _clearError();
      
      final index = _cycleEntries.indexWhere((e) => e.id == entry.id);
      if (index == -1) {
        return false;
      }
      
      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      
      // Try to update in Supabase first (if authenticated)
      if (_supabaseService.isAuthenticated && entry.userId != 'guest_user') {
        try {
          final savedEntry = await _supabaseService.updateCycleEntry(updatedEntry);
          _cycleEntries[index] = savedEntry;
          debugPrint('Updated entry in Supabase: ${savedEntry.id}');
        } catch (e) {
          debugPrint('Failed to update in Supabase, updating locally: $e');
          _cycleEntries[index] = updatedEntry;
          await _saveCycleEntriesToStorage();
        }
      } else {
        // Update in local storage for guest users
        _cycleEntries[index] = updatedEntry;
        await _saveCycleEntriesToStorage();
      }
      
      _filterCurrentMonthEntries();
      
      // Recalculate based on updated user data
      await _calculateStatistics();
      await _predictNextCycle();
      _determineCurrentPhase();
      await _syncNotifications();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating cycle entry: $e');
      _setError('Failed to update cycle entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete cycle entry
  Future<bool> deleteCycleEntry(String entryId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final entry = _cycleEntries.firstWhere((e) => e.id == entryId);
      
      // Try to delete from Supabase first (if authenticated)
      if (_supabaseService.isAuthenticated && entry.userId != 'guest_user') {
        try {
          await _supabaseService.deleteCycleEntry(entryId);
          debugPrint('Deleted entry from Supabase: $entryId');
        } catch (e) {
          debugPrint('Failed to delete from Supabase, deleting locally: $e');
        }
      }
      
      _cycleEntries.removeWhere((entry) => entry.id == entryId);
      _filterCurrentMonthEntries();
      
      // Recalculate after deletion
      await _calculateStatistics();
      await _predictNextCycle();
      _determineCurrentPhase();
      await _syncNotifications();
      
      // Save to local storage (for guest users or as backup)
      await _saveCycleEntriesToStorage();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting cycle entry: $e');
      _setError('Failed to delete cycle entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate cycle statistics from user input data
  Future<void> _calculateStatistics() async {
    if (_cycleEntries.isEmpty) {
      // Reset to defaults when no data
      _averageCycleLength = Constants.defaultCycleLength;
      _averagePeriodLength = Constants.defaultPeriodLength;
      _cyclesTracked = 0;
      notifyListeners();
      return;
    }
    
    final periodEntries = _cycleEntries
        .where((entry) => entry.isPeriodDay)
        .toList();
    
    // Calculate average period length from user's input (can calculate with 1 entry)
      int totalPeriodDays = 0;
      int periodCount = 0;
      
      for (final entry in periodEntries) {
        if (entry.periodFlow != null) {
          totalPeriodDays += entry.periodFlow!;
          periodCount++;
        }
      }
      
      if (periodCount > 0) {
        _averagePeriodLength = (totalPeriodDays / periodCount).round();
    } else {
      _averagePeriodLength = Constants.defaultPeriodLength;
    }
    
    // Calculate average cycle length (needs at least 2 period entries)
    if (periodEntries.length >= 2) {
      // Calculate average cycle length from user's period dates
      int totalDays = 0;
      int cycleCount = 0;
      
      // Sort by date (most recent first)
      final sortedEntries = List<CycleEntry>.from(periodEntries)
        ..sort((a, b) => b.date.compareTo(a.date));
      
      for (int i = 0; i < sortedEntries.length - 1; i++) {
        final days = sortedEntries[i].date
            .difference(sortedEntries[i + 1].date)
            .inDays
            .abs();
        if (days > 0 && days < 100) { // Sanity check: cycle should be between 1-100 days
          totalDays += days;
          cycleCount++;
        }
      }
      
      if (cycleCount > 0) {
        _averageCycleLength = (totalDays / cycleCount).round();
      _cyclesTracked = cycleCount;
      } else {
        // If calculation failed, use default but keep cycles tracked
        _averageCycleLength = Constants.defaultCycleLength;
        _cyclesTracked = 0;
      }
    } else if (periodEntries.length == 1) {
      // Only one period entry - can't calculate cycle length yet
      _averageCycleLength = Constants.defaultCycleLength;
      _cyclesTracked = 0;
    } else {
      // No period entries
      _averageCycleLength = Constants.defaultCycleLength;
      _averagePeriodLength = Constants.defaultPeriodLength;
      _cyclesTracked = 0;
    }
    
    debugPrint('📊 Statistics calculated:');
    debugPrint('   Average Cycle Length: $_averageCycleLength days');
    debugPrint('   Average Period Length: $_averagePeriodLength days');
    debugPrint('   Cycles Tracked: $_cyclesTracked');
    debugPrint('   Period Entries: ${periodEntries.length}');
    
    notifyListeners();
  }

  // Predict next cycle based on user's input data
  Future<void> _predictNextCycle() async {
    if (_cycleEntries.isEmpty) {
      // No user data - clear predictions
      _nextPeriodStart = null;
      _nextOvulationDate = null;
      _fertileWindow = [];
      return;
    }
    
    final periodEntries = _cycleEntries
        .where((entry) => entry.isPeriodDay)
        .toList();
    
    if (periodEntries.isEmpty) {
      // No period data - clear predictions
      _nextPeriodStart = null;
      _nextOvulationDate = null;
      _fertileWindow = [];
      return;
    }
    
    // Get the most recent period entry
    final lastPeriod = periodEntries.first;
    
    // Predict next period based on calculated average cycle length (from user data)
    _nextPeriodStart = lastPeriod.date.add(Duration(days: _averageCycleLength));
    
    // Predict ovulation (14 days before next period, or use calculated luteal phase)
    final lutealPhase = _averageCycleLength > 14 ? 14 : (_averageCycleLength / 2).round();
    _nextOvulationDate = _nextPeriodStart!.subtract(Duration(days: lutealPhase));
    
    // Calculate fertile window (5 days before and 1 day after ovulation)
    _fertileWindow = [];
    for (int i = -5; i <= 1; i++) {
      _fertileWindow.add(_nextOvulationDate!.add(Duration(days: i)));
    }
  }

  // Get safe period start date (after fertile window ends)
  DateTime? get safePeriodStart {
    if (_fertileWindow.isEmpty || _nextPeriodStart == null) return null;
    // Safe period starts 1 day after fertile window ends
    final fertileEnd = _fertileWindow.last;
    return fertileEnd.add(const Duration(days: 1));
  }

  Future<void> _syncNotifications() async {
    final notificationProvider = _notificationProvider;
    if (notificationProvider == null) {
      debugPrint('⚠️ Notification provider not attached yet');
      return;
    }

    try {
      // Ensure notifications are enabled - enable by default if cycle data exists
      if (!notificationProvider.notificationsEnabled && _cycleEntries.isNotEmpty) {
        debugPrint('🔔 Enabling notifications automatically as cycle data exists');
        await notificationProvider.requestPermissions();
        // Note: We can't directly enable, but permissions request helps
      }

      if (!notificationProvider.notificationsEnabled) {
        debugPrint('⚠️ Notifications are disabled by user');
        await notificationProvider.cancelNotification(Constants.nextCycleDateId);
        await notificationProvider.cancelNotification(Constants.safePeriodId);
        await notificationProvider.cancelNotification(Constants.periodReminderId);
        return;
      }

      final now = DateTime.now();

      // Schedule next period date notification
      if (_nextPeriodStart != null) {
        if (_nextPeriodStart!.isAfter(now)) {
          final daysUntilPeriod = _nextPeriodStart!.difference(now).inDays;
          final formattedDate = DateFormat.yMMMMd().format(_nextPeriodStart!);
          final bodyBuffer = StringBuffer('Your next period is expected on $formattedDate');

          if (daysUntilPeriod > 1) {
            bodyBuffer.write(' (in $daysUntilPeriod days).');
          } else if (daysUntilPeriod == 1) {
            bodyBuffer.write(' (tomorrow).');
          } else {
            bodyBuffer.write('.');
          }
          bodyBuffer.write(' Keep tracking your symptoms for more accurate predictions.');

          // Schedule notification on the period date
          await notificationProvider.scheduleNextCycleDateNotification(
            nextCycleDate: _nextPeriodStart!,
            title: 'Next period reminder',
            body: bodyBuffer.toString(),
          );

          // Also schedule a reminder 2-3 days before the period
          if (daysUntilPeriod >= 3) {
            final reminderDate = _nextPeriodStart!.subtract(const Duration(days: 2));
            if (reminderDate.isAfter(now)) {
              final reminderFormattedDate = DateFormat.yMMMMd().format(_nextPeriodStart!);
              await notificationProvider.schedulePeriodReminder(
                date: reminderDate,
                title: 'Period approaching soon',
                body: 'Your period is expected in 2 days (on $reminderFormattedDate). Make sure you\'re prepared!',
              );
              debugPrint('✅ Scheduled period reminder for ${DateFormat.yMMMMd().format(reminderDate)}');
            }
          }

          debugPrint('✅ Scheduled next period notification for ${DateFormat.yMMMMd().format(_nextPeriodStart!)}');
        } else {
          await notificationProvider.cancelNotification(Constants.nextCycleDateId);
          await notificationProvider.cancelNotification(Constants.periodReminderId);
        }
      } else {
        await notificationProvider.cancelNotification(Constants.nextCycleDateId);
        await notificationProvider.cancelNotification(Constants.periodReminderId);
      }

      // Schedule safe period notification
      final safeStart = safePeriodStart;
      if (safeStart != null && safeStart.isAfter(now)) {
        final formattedSafeDate = DateFormat.yMMMMd().format(safeStart);
        final daysUntilSafe = safeStart.difference(now).inDays;
        final safeBody = daysUntilSafe > 0
            ? 'Your predicted safe period begins on $formattedSafeDate (in $daysUntilSafe days). Plan ahead and keep your wellness logs updated.'
            : 'Your predicted safe period begins on $formattedSafeDate. Plan ahead and keep your wellness logs updated.';
        
        await notificationProvider.scheduleSafePeriodNotification(
          safePeriodStart: safeStart,
          title: 'Safe period starts soon',
          body: safeBody,
        );
        debugPrint('✅ Scheduled safe period notification for ${DateFormat.yMMMMd().format(safeStart)}');
      } else {
        await notificationProvider.cancelNotification(Constants.safePeriodId);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to sync notifications: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }

  // Determine current phase
  void _determineCurrentPhase() {
    if (_nextPeriodStart == null || _nextOvulationDate == null) {
      _currentPhase = CyclePhase.unknown;
      return;
    }
    
    final now = DateTime.now();
    final daysUntilPeriod = _nextPeriodStart!.difference(now).inDays;
    final daysUntilOvulation = _nextOvulationDate!.difference(now).inDays;
    
    if (daysUntilPeriod <= 0) {
      _currentPhase = CyclePhase.menstrual;
    } else if (daysUntilOvulation <= 0 && daysUntilOvulation >= -1) {
      _currentPhase = CyclePhase.ovulation;
    } else if (daysUntilOvulation > 0) {
      _currentPhase = CyclePhase.follicular;
    } else {
      _currentPhase = CyclePhase.luteal;
    }
  }

  // Filter entries for current month
  void _filterCurrentMonthEntries() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    _currentMonthEntries = _cycleEntries
        .where((entry) => 
            entry.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .toList();
  }

  // Get entries for specific date range
  List<CycleEntry> getEntriesForDateRange(DateTime start, DateTime end) {
    return _cycleEntries
        .where((entry) => 
            entry.date.isAfter(start.subtract(const Duration(days: 1))) &&
            entry.date.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  // Get period entries
  List<CycleEntry> get periodEntries {
    return _cycleEntries
        .where((entry) => entry.isPeriodDay)
        .toList();
  }

  // Get symptom entries
  List<CycleEntry> getSymptomEntries(String symptom) {
    return _cycleEntries
        .where((entry) => entry.symptoms.contains(symptom))
        .toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get cycle insights
  Map<String, dynamic> get cycleInsights {
    return {
      'currentPhase': _currentPhase.toString().split('.').last,
      'daysUntilNextPeriod': _nextPeriodStart?.difference(DateTime.now()).inDays,
      'daysUntilOvulation': _nextOvulationDate?.difference(DateTime.now()).inDays,
      'isInFertileWindow': _fertileWindow.any((date) => 
          date.difference(DateTime.now()).inDays.abs() <= 1),
      'cycleRegularity': _calculateCycleRegularity(),
    };
  }

  // Get detailed cycle trends
  Map<String, dynamic> get cycleTrends {
    if (_cycleEntries.isEmpty) return {};
    
    final periodEntries = _cycleEntries
        .where((entry) => entry.isPeriodDay)
        .toList();
    
    if (periodEntries.length < 2) return {};
    
    // Calculate cycle lengths
    List<int> cycleLengths = [];
    for (int i = 0; i < periodEntries.length - 1; i++) {
      final days = periodEntries[i].date
          .difference(periodEntries[i + 1].date)
          .inDays
          .abs();
      cycleLengths.add(days);
    }
    
    final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final minLength = cycleLengths.reduce((a, b) => a < b ? a : b);
    final maxLength = cycleLengths.reduce((a, b) => a > b ? a : b);
    final variance = cycleLengths
        .map((length) => (length - average) * (length - average))
        .reduce((a, b) => a + b) / cycleLengths.length;
    final standardDeviation = math.sqrt(variance);
    
    return {
      'cycleLengths': cycleLengths,
      'average': average,
      'min': minLength,
      'max': maxLength,
      'standardDeviation': standardDeviation,
      'regularity': _calculateCycleRegularity(),
    };
  }

  // Get symptom analysis
  Map<String, dynamic> get symptomAnalysis {
    final entries = _cycleEntries;
    if (entries.isEmpty) return {};
    
    Map<String, List<SymptomSeverity>> symptomData = {};
    
    for (final entry in entries) {
      for (final symptom in entry.symptoms) {
        if (!symptomData.containsKey(symptom)) {
          symptomData[symptom] = [];
        }
        if (entry.symptomSeverity.containsKey(symptom)) {
          symptomData[symptom]!.add(entry.symptomSeverity[symptom]!);
        }
      }
    }
    
    Map<String, Map<String, dynamic>> result = {};
    
    for (final entry in symptomData.entries) {
      final symptom = entry.key;
      final severities = entry.value;
      
      if (severities.isNotEmpty) {
        final frequency = (severities.length / entries.length * 100).round();
        final avgSeverity = severities.map((s) => s.index + 1).reduce((a, b) => a + b) / severities.length;
        
        result[symptom] = {
          'frequency': frequency,
          'avgSeverity': avgSeverity,
          'count': severities.length,
        };
      }
    }
    
    return result;
  }

  // Get lifestyle insights
  Map<String, dynamic> get lifestyleInsights {
    final entries = _cycleEntries;
    if (entries.isEmpty) return {};
    
    double totalSleep = 0;
    double totalWater = 0;
    double totalStress = 0;
    Map<String, int> moodCounts = {};
    Map<String, int> activityCounts = {};
    int validSleepEntries = 0;
    int validWaterEntries = 0;
    int validStressEntries = 0;
    
    for (final entry in entries) {
      if (entry.sleepHours != null) {
        totalSleep += entry.sleepHours!;
        validSleepEntries++;
      }
      if (entry.waterIntake != null) {
        totalWater += entry.waterIntake!;
        validWaterEntries++;
      }
      if (entry.stressLevel != null) {
        totalStress += entry.stressLevel!;
        validStressEntries++;
      }
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
      }
      for (final activity in entry.activities) {
        activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
      }
    }
    
    return {
      'avgSleep': validSleepEntries > 0 ? totalSleep / validSleepEntries : null,
      'avgWater': validWaterEntries > 0 ? totalWater / validWaterEntries : null,
      'avgStress': validStressEntries > 0 ? totalStress / validStressEntries : null,
      'commonMood': moodCounts.isNotEmpty 
          ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
      'commonActivity': activityCounts.isNotEmpty 
          ? activityCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
      'moodDistribution': moodCounts,
      'activityDistribution': activityCounts,
    };
  }

  // Check if running in guest mode
  bool get isGuestMode => !_supabaseService.isAuthenticated;

  // Clear all cycle data (for testing/reset)
  Future<void> clearAllData() async {
    try {
      _setLoading(true);
      _clearError();
      
      _cycleEntries.clear();
      _currentMonthEntries.clear();
      _nextPeriodStart = null;
      _nextOvulationDate = null;
      _fertileWindow.clear();
      _currentPhase = CyclePhase.unknown;
      _averageCycleLength = Constants.defaultCycleLength;
      _averagePeriodLength = Constants.defaultPeriodLength;
      _cyclesTracked = 0;
      
      if (_notificationProvider != null) {
        await _notificationProvider!.cancelNotification(Constants.nextCycleDateId);
        await _notificationProvider!.cancelNotification(Constants.safePeriodId);
      }
      
      // Clear from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cycle_entries');
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add sample data for testing
  Future<void> addSampleData([String? userId]) async {
    if (_cycleEntries.isNotEmpty) return; // Don't add if already has data
    
    try {
      _setLoading(true);
      _clearError();
      
      final sampleUserId = userId ?? 'guest_user';
      
      final now = DateTime.now();
      final sampleEntries = [
        CycleEntry(
          id: const Uuid().v4(),
          userId: sampleUserId,
          date: now.subtract(const Duration(days: 28)),
          phase: CyclePhase.menstrual,
          isPeriodDay: true,
          periodFlow: 3,
          symptoms: ['cramps', 'fatigue'],
          symptomSeverity: {'cramps': SymptomSeverity.moderate, 'fatigue': SymptomSeverity.mild},
          notes: 'Sample entry 1',
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 28)),
          sleepHours: 7,
          waterIntake: 2000,
          stressLevel: 4,
          mood: 'neutral',
          activities: ['walking'],
          tookMedication: false,
        ),
        CycleEntry(
          id: const Uuid().v4(),
          userId: sampleUserId,
          date: now.subtract(const Duration(days: 14)),
          phase: CyclePhase.ovulation,
          isPeriodDay: false,
          symptoms: ['mild cramps'],
          symptomSeverity: {'mild cramps': SymptomSeverity.mild},
          notes: 'Sample entry 2',
          createdAt: now.subtract(const Duration(days: 14)),
          updatedAt: now.subtract(const Duration(days: 14)),
          sleepHours: 8,
          waterIntake: 2500,
          stressLevel: 2,
          mood: 'happy',
          activities: ['yoga', 'meditation'],
          tookMedication: false,
        ),
        CycleEntry(
          id: const Uuid().v4(),
          userId: sampleUserId,
          date: now.subtract(const Duration(days: 7)),
          phase: CyclePhase.luteal,
          isPeriodDay: false,
          symptoms: ['bloating', 'mood swings'],
          symptomSeverity: {'bloating': SymptomSeverity.mild, 'mood swings': SymptomSeverity.moderate},
          notes: 'Sample entry 3',
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 7)),
          sleepHours: 6,
          waterIntake: 1800,
          stressLevel: 6,
          mood: 'irritable',
          activities: ['reading'],
          tookMedication: false,
        ),
      ];
      
      _cycleEntries.addAll(sampleEntries);
      _filterCurrentMonthEntries();
      await _calculateStatistics();
      await _predictNextCycle();
      _determineCurrentPhase();
      
      // Save to local storage
      await _saveCycleEntriesToStorage();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add sample data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Calculate cycle regularity score
  double _calculateCycleRegularity() {
    if (_cycleEntries.length < 3) return 0.0;
    
    final periodEntries = _cycleEntries
        .where((entry) => entry.isPeriodDay)
        .toList();
    
    if (periodEntries.length < 3) return 0.0;
    
    List<int> cycleLengths = [];
    for (int i = 0; i < periodEntries.length - 1; i++) {
      final days = periodEntries[i].date
          .difference(periodEntries[i + 1].date)
          .inDays
          .abs();
      cycleLengths.add(days);
    }
    
    final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final variance = cycleLengths
        .map((length) => (length - average) * (length - average))
        .reduce((a, b) => a + b) / cycleLengths.length;
    final standardDeviation = math.sqrt(variance);
    
    // Regularity score: 100 - (standard deviation * 10)
    return (100 - (standardDeviation * 10)).clamp(0.0, 100.0);
  }
}
