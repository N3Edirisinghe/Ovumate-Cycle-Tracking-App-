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
      
      // If user is authenticated (not guest), first migrate any local guest data
      if (_supabaseService.isAuthenticated && effectiveUserId != 'guest_user') {
        await _migrateLocalGuestEntriesToSupabase(effectiveUserId);
      }
      
      // Always load from local storage first (as backup)
      await _loadCycleEntriesFromStorage();
      final localEntries = List<CycleEntry>.from(_cycleEntries);
      debugPrint('📦 Loaded ${localEntries.length} entries from local storage');
      if (localEntries.isNotEmpty) {
        debugPrint('📅 Date range: ${localEntries.last.date} to ${localEntries.first.date}');
        debugPrint('👤 User IDs in local entries: ${localEntries.map((e) => e.userId).toSet().toList()}');
      }
      
      // Try to load from Supabase if authenticated
      if (_supabaseService.isAuthenticated && effectiveUserId != 'guest_user') {
        try {
          final supabaseEntries = await _supabaseService.getCycleEntries(effectiveUserId);
          debugPrint('☁️ Loaded ${supabaseEntries.length} entries from Supabase');
          
          if (supabaseEntries.isNotEmpty) {
            // Use Supabase data as primary source
            _cycleEntries = List<CycleEntry>.from(supabaseEntries);
            
            // Merge with local entries that might not be in Supabase yet
            // Include ALL local entries regardless of userId for backward compatibility
            final supabaseIds = supabaseEntries.map((e) => e.id).toSet();
            // Get ALL local entries that aren't in Supabase (regardless of userId)
            final localOnlyEntries = localEntries
                .where((e) => !supabaseIds.contains(e.id))
                .toList();
            
            debugPrint('🔍 Merge check: ${localEntries.length} local entries, ${supabaseEntries.length} Supabase entries');
            debugPrint('   Local entries not in Supabase: ${localOnlyEntries.length}');
            if (localOnlyEntries.isNotEmpty) {
              debugPrint('   Local entry user IDs: ${localOnlyEntries.map((e) => e.userId).toSet().toList()}');
            }
            
            // Always merge local entries that aren't in Supabase (even if they have different userId)
            // This ensures old data is never lost
            if (localOnlyEntries.isNotEmpty) {
              debugPrint('🔄 Merging ${localOnlyEntries.length} local entries not in Supabase...');
              // Update userId for old entries to match current user
              final updatedLocalEntries = localOnlyEntries.map((e) => 
                e.copyWith(userId: effectiveUserId)
              ).toList();
              _cycleEntries.addAll(updatedLocalEntries);
              debugPrint('✅ After merge: ${_cycleEntries.length} total entries');
              // Try to sync these to Supabase
              await syncLocalEntriesToSupabase();
            } else {
              debugPrint('✅ All local entries already in Supabase');
            }
          } else {
            // Supabase is empty, use ALL local entries if available (for backward compatibility)
            if (localEntries.isNotEmpty) {
              debugPrint('⚠️ Supabase is empty, using all local entries');
              // Update userId for all local entries to match current user
              _cycleEntries = localEntries.map((e) => 
                e.copyWith(userId: effectiveUserId)
              ).toList();
              // Try to sync local entries to Supabase
              await syncLocalEntriesToSupabase();
            } else {
              _cycleEntries = [];
            }
          }
          
          // Save merged data back to local storage
          await _saveCycleEntriesToStorage();
        } catch (e) {
          debugPrint('⚠️ Failed to load from Supabase, using local storage: $e');
          // Use ALL local entries as fallback (for backward compatibility with old data)
          debugPrint('📦 Using all ${localEntries.length} local entries as fallback');
          // Update userId for all local entries to match current user
          _cycleEntries = localEntries.map((e) => 
            e.copyWith(userId: effectiveUserId)
          ).toList();
          // Try to sync local entries to Supabase if we're authenticated
          if (_supabaseService.isAuthenticated) {
            await syncLocalEntriesToSupabase();
          }
        }
      } else {
        // Guest mode: use ALL local entries (including old entries with different userIds)
        // Include ALL entries regardless of userId for maximum backward compatibility
        _cycleEntries = localEntries.map((e) => 
          e.userId.isEmpty || (e.userId != 'guest_user' && e.userId != effectiveUserId)
              ? e.copyWith(userId: 'guest_user')
              : e
        ).toList();
        debugPrint('👤 Guest mode: using ${_cycleEntries.length} local entries (including ALL old entries)');
      }
      
      // Sort entries by date (most recent first)
      _cycleEntries.sort((a, b) => b.date.compareTo(a.date));
      _filterCurrentMonthEntries();
      
      debugPrint('✅ Total entries loaded: ${_cycleEntries.length}');
      
      // Calculate statistics and predictions based on user data
      await _calculateStatistics();
      await _predictNextCycle();
      _determineCurrentPhase();
      await _syncNotifications();
    } catch (e) {
      debugPrint('❌ Error initializing cycle provider: $e');
      _setError('Failed to initialize cycle data: $e');
      // Try to load from local storage as last resort
      try {
        await _loadCycleEntriesFromStorage();
        // Use ALL loaded entries regardless of userId for backward compatibility
        final effectiveUserId = userId ?? _supabaseService.currentUserId ?? 'guest_user';
        if (_supabaseService.isAuthenticated && effectiveUserId != 'guest_user') {
          // Update userId for all entries to match current user
          _cycleEntries = _cycleEntries.map((e) => 
            e.copyWith(userId: effectiveUserId)
          ).toList();
        } else {
          // Guest mode: ensure all entries have guest_user as userId
          _cycleEntries = _cycleEntries.map((e) => 
            e.userId.isEmpty ? e.copyWith(userId: 'guest_user') : e
          ).where((e) => 
            e.userId == 'guest_user' || e.userId == effectiveUserId
          ).toList();
        }
        _filterCurrentMonthEntries();
        debugPrint('✅ Loaded ${_cycleEntries.length} entries from local storage as fallback');
      } catch (localError) {
        debugPrint('❌ Failed to load from local storage: $localError');
        _cycleEntries = [];
      }
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
      
      debugPrint('🔍 Checking local storage for cycle entries...');
      debugPrint('📄 JSON length: ${entriesJson?.length ?? 0}');
      
      if (entriesJson != null && entriesJson.isNotEmpty) {
        try {
          final List<dynamic> entriesList = json.decode(entriesJson);
          debugPrint('📋 Found ${entriesList.length} entries in JSON');
          
          final List<CycleEntry> loadedEntries = [];
          int successCount = 0;
          int failCount = 0;
          
          // Parse each entry individually to avoid losing all entries if one fails
          for (int i = 0; i < entriesList.length; i++) {
            try {
              final entryData = entriesList[i];
              if (entryData is Map<String, dynamic>) {
                final entry = CycleEntry.fromJson(entryData);
                // Only add valid entries (with id and date)
                if (entry.id.isNotEmpty) {
                  loadedEntries.add(entry);
                  successCount++;
                } else {
                  debugPrint('⚠️ Entry $i has empty ID, skipping');
                  failCount++;
                }
              } else {
                debugPrint('⚠️ Entry $i is not a Map, skipping');
                failCount++;
              }
            } catch (e) {
              debugPrint('⚠️ Failed to parse entry $i: $e');
              debugPrint('   Entry data: ${entriesList[i]}');
              failCount++;
              // Continue with next entry instead of failing completely
            }
          }
          
          _cycleEntries = loadedEntries;
          debugPrint('✅ Successfully loaded ${_cycleEntries.length} entries from local storage');
          debugPrint('   ✅ Parsed: $successCount, ❌ Failed: $failCount');
          
          if (_cycleEntries.isNotEmpty) {
            final sorted = List<CycleEntry>.from(_cycleEntries);
            sorted.sort((a, b) => a.date.compareTo(b.date));
            debugPrint('📅 Date range: ${sorted.first.date} to ${sorted.last.date}');
            debugPrint('👤 User IDs: ${_cycleEntries.map((e) => e.userId).toSet().toList()}');
          }
          
          _filterCurrentMonthEntries();
        } catch (jsonError) {
          debugPrint('❌ Failed to decode JSON: $jsonError');
          debugPrint('   JSON preview: ${entriesJson.substring(0, entriesJson.length > 200 ? 200 : entriesJson.length)}...');
          _cycleEntries = [];
        }
      } else {
        debugPrint('📦 No cycle entries found in local storage (key: cycle_entries)');
        // Check for alternative keys
        final allKeys = prefs.getKeys();
        debugPrint('🔑 All SharedPreferences keys: ${allKeys.where((k) => k.contains('cycle') || k.contains('entry')).toList()}');
        _cycleEntries = [];
      }
    } catch (e) {
      debugPrint('❌ Failed to load cycle entries: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      // Don't clear entries if we already have some loaded
      if (_cycleEntries.isEmpty) {
        _cycleEntries = [];
      }
      _filterCurrentMonthEntries();
    }
  }
  
  // Force reload all cycle entries (useful for debugging)
  Future<void> forceReload() async {
    debugPrint('🔄 Force reloading cycle entries...');
    final effectiveUserId = _supabaseService.currentUserId ?? 'guest_user';
    await initialize(effectiveUserId);
    notifyListeners();
  }
  
  // Debug method to check what's in storage
  Future<void> debugStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString('cycle_entries');
      
      debugPrint('🔍 DEBUG STORAGE:');
      debugPrint('   Has cycle_entries key: ${entriesJson != null}');
      if (entriesJson != null) {
        debugPrint('   JSON length: ${entriesJson.length}');
        try {
          final List<dynamic> entriesList = json.decode(entriesJson);
          debugPrint('   Total entries in JSON: ${entriesList.length}');
          if (entriesList.isNotEmpty) {
            debugPrint('   First entry: ${entriesList.first}');
            debugPrint('   Last entry: ${entriesList.last}');
          }
        } catch (e) {
          debugPrint('   JSON decode error: $e');
        }
      }
      debugPrint('   Current _cycleEntries count: ${_cycleEntries.length}');
      if (_cycleEntries.isNotEmpty) {
        final sorted = List<CycleEntry>.from(_cycleEntries);
        sorted.sort((a, b) => a.date.compareTo(b.date));
        debugPrint('   Date range: ${sorted.first.date} to ${sorted.last.date}');
        debugPrint('   User IDs: ${_cycleEntries.map((e) => e.userId).toSet().toList()}');
        debugPrint('   Period entries: ${_cycleEntries.where((e) => e.isPeriodDay).length}');
      }
    } catch (e) {
      debugPrint('❌ Debug storage error: $e');
    }
  }

  // Save cycle entries to local storage
  Future<void> _saveCycleEntriesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = json.encode(_cycleEntries.map((e) => e.toJson()).toList());
      await prefs.setString('cycle_entries', entriesJson);
      debugPrint('💾 Saved ${_cycleEntries.length} entries to local storage');
    } catch (e) {
      debugPrint('❌ Failed to save cycle entries: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  /// One-time migration: move any locally stored "guest_user" entries to Supabase
  /// for the currently authenticated user, then clear migrated local data.
  Future<void> _migrateLocalGuestEntriesToSupabase(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString('cycle_entries');
      if (entriesJson == null || entriesJson.isEmpty) {
        return;
      }

      final List<dynamic> entriesList = json.decode(entriesJson);
      final List<CycleEntry> allLocalEntries = entriesList
          .map((entry) => CycleEntry.fromJson(entry as Map<String, dynamic>))
          .toList();

      final guestEntries =
          allLocalEntries.where((e) => e.userId == 'guest_user').toList();
      if (guestEntries.isEmpty) {
        return;
      }

      debugPrint(
          '🔄 Migrating ${guestEntries.length} local guest entries to Supabase for user $userId');

      final now = DateTime.now();
      for (final entry in guestEntries) {
        try {
          final migrated = entry.copyWith(
            id: const Uuid().v4(),
            userId: userId,
            createdAt: now,
            updatedAt: now,
          );
          await _supabaseService.addCycleEntry(migrated);
        } catch (e) {
          debugPrint('⚠️ Failed to migrate local entry ${entry.id}: $e');
        }
      }

      // Keep only non-guest entries locally (or clear everything if none)
      final remaining =
          allLocalEntries.where((e) => e.userId != 'guest_user').toList();
      if (remaining.isEmpty) {
        await prefs.remove('cycle_entries');
      } else {
        final updatedJson =
            json.encode(remaining.map((e) => e.toJson()).toList());
        await prefs.setString('cycle_entries', updatedJson);
      }

      debugPrint('✅ Guest data migration completed');
    } catch (e) {
      debugPrint('⚠️ Error during guest data migration: $e');
    }
  }

  // Add new cycle entry
  Future<bool> addCycleEntry(CycleEntry entry) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Get current authenticated user ID (if logged in)
      final currentUserId = _supabaseService.currentUserId;
      final isAuthenticated = _supabaseService.isAuthenticated;
      
      // Ensure userId is set correctly: use authenticated user ID if logged in, otherwise use entry's userId
      final effectiveUserId = isAuthenticated && currentUserId != null 
          ? currentUserId 
          : (entry.userId.isNotEmpty ? entry.userId : 'guest_user');
      
      // Ensure entry has a unique ID and timestamps
      final now = DateTime.now();
      final entryToAdd = entry.id.isEmpty 
        ? CycleEntry(
            id: const Uuid().v4(),
            userId: effectiveUserId,
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
            userId: effectiveUserId,
            updatedAt: now,
          );
      
      // Always save to local storage first (as backup)
      _cycleEntries.insert(0, entryToAdd);
      await _saveCycleEntriesToStorage();
      
      // Try to save to Supabase if authenticated
      if (isAuthenticated && currentUserId != null && effectiveUserId != 'guest_user') {
        try {
          final savedEntry = await _supabaseService.addCycleEntry(entryToAdd);
          // Update local entry with server response (in case server modified anything)
          final index = _cycleEntries.indexWhere((e) => e.id == entryToAdd.id);
          if (index != -1) {
            _cycleEntries[index] = savedEntry;
            await _saveCycleEntriesToStorage();
          }
          debugPrint('✅ Saved entry to Supabase: ${savedEntry.id}');
        } catch (e) {
          debugPrint('⚠️ Failed to save to Supabase (saved locally): $e');
          // Entry is already saved locally, so user can continue working
          // Will be synced on next login/initialization
        }
      } else {
        debugPrint('💾 Saved entry locally (guest mode): ${entryToAdd.id}');
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
      debugPrint('❌ Error adding cycle entry: $e');
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
        debugPrint('⚠️ Entry not found: ${entry.id}');
        return false;
      }
      
      // Get current authenticated user ID (if logged in)
      final currentUserId = _supabaseService.currentUserId;
      final isAuthenticated = _supabaseService.isAuthenticated;
      
      // Ensure userId is set correctly
      final effectiveUserId = isAuthenticated && currentUserId != null 
          ? currentUserId 
          : (entry.userId.isNotEmpty ? entry.userId : 'guest_user');
      
      final updatedEntry = entry.copyWith(
        userId: effectiveUserId,
        updatedAt: DateTime.now(),
      );
      
      // Always update locally first (as backup)
      _cycleEntries[index] = updatedEntry;
      await _saveCycleEntriesToStorage();
      
      // Try to update in Supabase if authenticated
      if (isAuthenticated && currentUserId != null && effectiveUserId != 'guest_user') {
        try {
          final savedEntry = await _supabaseService.updateCycleEntry(updatedEntry);
          _cycleEntries[index] = savedEntry;
          await _saveCycleEntriesToStorage();
          debugPrint('✅ Updated entry in Supabase: ${savedEntry.id}');
        } catch (e) {
          debugPrint('⚠️ Failed to update in Supabase (updated locally): $e');
          // Entry is already updated locally, will be synced later
        }
      } else {
        debugPrint('💾 Updated entry locally (guest mode): ${updatedEntry.id}');
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
      debugPrint('❌ Error updating cycle entry: $e');
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
      final currentUserId = _supabaseService.currentUserId;
      final isAuthenticated = _supabaseService.isAuthenticated;
      
      // Try to delete from Supabase first (if authenticated)
      if (isAuthenticated && currentUserId != null && entry.userId != 'guest_user') {
        try {
          await _supabaseService.deleteCycleEntry(entryId);
          debugPrint('✅ Deleted entry from Supabase: $entryId');
        } catch (e) {
          debugPrint('⚠️ Failed to delete from Supabase (deleting locally): $e');
          // Continue to delete locally even if Supabase delete fails
        }
      }
      
      // Always delete from local storage
      _cycleEntries.removeWhere((entry) => entry.id == entryId);
      _filterCurrentMonthEntries();
      
      // Save updated list to local storage
      await _saveCycleEntriesToStorage();
      
      // Recalculate after deletion
      await _calculateStatistics();
      await _predictNextCycle();
      _determineCurrentPhase();
      await _syncNotifications();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting cycle entry: $e');
      _setError('Failed to delete cycle entry: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sync local entries to Supabase (for entries that failed to save previously)
  /// This should be called when user logs in or connectivity is restored
  Future<void> syncLocalEntriesToSupabase() async {
    if (!_supabaseService.isAuthenticated) {
      debugPrint('⚠️ Cannot sync: user not authenticated');
      return;
    }
    
    final currentUserId = _supabaseService.currentUserId;
    if (currentUserId == null) {
      debugPrint('⚠️ Cannot sync: no user ID');
      return;
    }
    
    try {
      debugPrint('🔄 Syncing local entries to Supabase...');
      
      // Get all entries from Supabase to check which ones already exist
      final supabaseEntries = await _supabaseService.getCycleEntries(currentUserId);
      final supabaseEntryIds = supabaseEntries.map((e) => e.id).toSet();
      
      // Find local entries that don't exist in Supabase
      final entriesToSync = _cycleEntries
          .where((entry) => 
              entry.userId == currentUserId && 
              !supabaseEntryIds.contains(entry.id))
          .toList();
      
      if (entriesToSync.isEmpty) {
        debugPrint('✅ All entries already synced');
        return;
      }
      
      debugPrint('📤 Syncing ${entriesToSync.length} entries to Supabase...');
      
      int successCount = 0;
      for (final entry in entriesToSync) {
        try {
          // Ensure userId is correct
          final entryToSync = entry.copyWith(userId: currentUserId);
          await _supabaseService.addCycleEntry(entryToSync);
          successCount++;
        } catch (e) {
          debugPrint('⚠️ Failed to sync entry ${entry.id}: $e');
        }
      }
      
      debugPrint('✅ Synced $successCount/${entriesToSync.length} entries to Supabase');
      
      // Reload from Supabase to get the latest data
      if (successCount > 0) {
        await _loadCycleEntriesFromSupabase(currentUserId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error syncing entries to Supabase: $e');
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
