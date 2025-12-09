import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isPeriodDay = false;
  int? _periodFlow;
  CyclePhase _selectedPhase = CyclePhase.unknown;
  
  // Symptoms
  final List<String> _selectedSymptoms = [];
  final Map<String, SymptomSeverity> _symptomSeverity = {};
  
  // Lifestyle tracking
  double? _sleepHours;
  int? _waterIntake;
  int? _stressLevel;
  String? _selectedMood;
  final List<String> _selectedActivities = [];
  bool _tookMedication = false;
  final _medicationNotesController = TextEditingController();
  
  // Available options - using translation keys
  List<String> get _symptomOptions => [
    'cycle_tracking.symptoms_options.cramps'.tr(),
    'cycle_tracking.symptoms_options.bloating'.tr(),
    'cycle_tracking.symptoms_options.tender_breasts'.tr(),
    'cycle_tracking.symptoms_options.acne'.tr(),
    'cycle_tracking.symptoms_options.food_cravings'.tr(),
    'cycle_tracking.symptoms_options.headache'.tr(),
    'cycle_tracking.symptoms_options.back_pain'.tr(),
    'cycle_tracking.symptoms_options.nausea'.tr(),
    'cycle_tracking.symptoms_options.dizziness'.tr(),
    'cycle_tracking.symptoms_options.hot_flashes'.tr(),
    'cycle_tracking.symptoms_options.insomnia'.tr(),
    'cycle_tracking.symptoms_options.anxiety'.tr(),
    'cycle_tracking.symptoms_options.depression'.tr(),
  ];
  
  List<String> get _moodOptions => [
    'cycle_tracking.moods.happy'.tr(),
    'cycle_tracking.moods.calm'.tr(),
    'cycle_tracking.moods.energetic'.tr(),
    'cycle_tracking.moods.irritable'.tr(),
    'cycle_tracking.moods.anxious'.tr(),
    'cycle_tracking.moods.sad'.tr(),
    'cycle_tracking.moods.stressed'.tr(),
    'cycle_tracking.moods.focused'.tr(),
    'cycle_tracking.moods.tired'.tr(),
    'cycle_tracking.moods.excited'.tr(),
  ];
  
  List<String> get _activityOptions => [
    'cycle_tracking.activities.exercise'.tr(),
    'cycle_tracking.activities.yoga'.tr(),
    'cycle_tracking.activities.meditation'.tr(),
    'cycle_tracking.activities.reading'.tr(),
    'cycle_tracking.activities.socializing'.tr(),
    'cycle_tracking.activities.work'.tr(),
    'cycle_tracking.activities.rest'.tr(),
    'cycle_tracking.activities.shopping'.tr(),
    'cycle_tracking.activities.cooking'.tr(),
    'cycle_tracking.activities.cleaning'.tr(),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    _medicationNotesController.dispose();
    super.dispose();
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
        _symptomSeverity.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
        _symptomSeverity[symptom] = SymptomSeverity.mild;
      }
    });
  }

  void _updateSymptomSeverity(String symptom, SymptomSeverity severity) {
    setState(() {
      _symptomSeverity[symptom] = severity;
    });
  }

  void _toggleActivity(String activity) {
    setState(() {
      if (_selectedActivities.contains(activity)) {
        _selectedActivities.remove(activity);
      } else {
        _selectedActivities.add(activity);
      }
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Allow saving in guest mode for testing
      final userId = authProvider.currentUser?.id ?? 'guest_user';
      
      final entry = CycleEntry(
        id: const Uuid().v4(),
        userId: userId,
        date: _selectedDate,
        phase: _selectedPhase,
        isPeriodDay: _isPeriodDay,
        periodFlow: _periodFlow,
        symptoms: _selectedSymptoms,
        symptomSeverity: _symptomSeverity,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sleepHours: _sleepHours,
        waterIntake: _waterIntake,
        stressLevel: _stressLevel,
        mood: _selectedMood,
        activities: _selectedActivities,
        tookMedication: _tookMedication,
        medicationNotes: _medicationNotesController.text.trim().isEmpty 
            ? null 
            : _medicationNotesController.text.trim(),
      );
      
      // Ensure notification provider is initialized and permissions are requested
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.requestPermissions();
      
      final success = await cycleProvider.addCycleEntry(entry);
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cycle_tracking.entry.saved_successfully')),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
        
        // Notifications are automatically scheduled when entry is saved
        // Show info about scheduled notifications after a brief delay to ensure calculations are complete
        if (_isPeriodDay) {
          // Wait a moment for cycle calculations to complete
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted && cycleProvider.nextPeriodStart != null) {
            final nextPeriodDate = cycleProvider.nextPeriodStart!;
            final daysUntil = nextPeriodDate.difference(DateTime.now()).inDays;
            if (daysUntil > 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🔔 Notifications scheduled! You\'ll be reminded ${daysUntil >= 3 ? '2 days before and on' : 'on'} your next period date (${DateFormat.yMMMMd().format(nextPeriodDate)}).',
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        }
        
        // If this is a period day entry, show notification scheduling option
        if (_isPeriodDay) {
          _showNotificationSchedulingDialog(cycleProvider);
        } else {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(cycleProvider.errorMessage ?? context.tr('cycle_tracking.entry.save_failed'))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showNotificationSchedulingDialog(CycleProvider cycleProvider) {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Calculate next period date based on current entry and average cycle length
    final nextPeriodDate = _selectedDate.add(Duration(days: cycleProvider.averageCycleLength));
    
    // Calculate safe period (after fertile window)
    final ovulationDate = nextPeriodDate.subtract(const Duration(days: 14));
    final safePeriodStart = ovulationDate.add(const Duration(days: 2)); // 1 day after fertile window
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('notifications.schedule.title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('notifications.schedule.description')),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
              title: Text(context.tr('notifications.schedule.next_period')),
              subtitle: Text(DateFormat.yMMMMd().format(nextPeriodDate)),
              trailing: Switch(
                value: true, // Always enabled for this dialog
                onChanged: null, // Disabled - always on
              ),
            ),
            ListTile(
              leading: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
              title: Text(context.tr('notifications.schedule.safe_period')),
              subtitle: Text(DateFormat.yMMMMd().format(safePeriodStart)),
              trailing: Switch(
                value: true, // Always enabled for this dialog
                onChanged: null, // Disabled - always on
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('notifications.schedule.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Schedule notifications
              await _schedulePeriodNotifications(
                notificationProvider, 
                nextPeriodDate, 
                safePeriodStart
              );
              
              // Show confirmation
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.tr('notifications.schedule.success')),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text(context.tr('notifications.schedule.confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _schedulePeriodNotifications(
    NotificationProvider notificationProvider,
    DateTime nextPeriodDate,
    DateTime safePeriodStart,
  ) async {
    try {
      // Schedule next period notification
      await notificationProvider.scheduleNextCycleDateNotification(
        nextCycleDate: nextPeriodDate,
        title: context.tr('notifications.period_reminder.title'),
        body: context.tr('notifications.period_reminder.body', args: [DateFormat.yMMMMd().format(nextPeriodDate)]),
      );
      
      // Schedule safe period notification
      await notificationProvider.scheduleSafePeriodNotification(
        safePeriodStart: safePeriodStart,
        title: context.tr('notifications.safe_period.title'),
        body: context.tr('notifications.safe_period.body', args: [DateFormat.yMMMMd().format(safePeriodStart)]),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('notifications.schedule.failed')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Constants.backgroundColor),
      appBar: AppBar(
        title: Text(
          context.tr('cycle_tracking.entry.title'),
          style: const TextStyle(color: Colors.black),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: Text(
              context.tr('cycle_tracking.entry.save'),
              style: const TextStyle(color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cycle_tracking.entry.date'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 7)),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Period tracking
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cycle_tracking.entry.period_tracking'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      
                      // Is period day
                      SwitchListTile(
                        title: Text(context.tr('cycle_tracking.entry.is_period_day'), maxLines: 1, overflow: TextOverflow.ellipsis,),
                        value: _isPeriodDay,
                        onChanged: (value) {
                          setState(() {
                            _isPeriodDay = value;
                            if (!value) {
                              _periodFlow = null;
                            }
                          });
                        },
                      ),
                      
                      if (_isPeriodDay) ...[
                        const SizedBox(height: 16),
                        Text(
                          context.tr('cycle_tracking.entry.flow_intensity'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final flow = index + 1;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _periodFlow = flow;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _periodFlow == flow
                                        ? const Color(Constants.periodColor)
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    flow.toString(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _periodFlow == flow ? Colors.white : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.tr('cycle_tracking.entry.light'), style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                            Text(context.tr('cycle_tracking.entry.heavy'), style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis,),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Cycle phase
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cycle_tracking.entry.cycle_phase'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: CyclePhase.values.map((phase) {
                          if (phase == CyclePhase.unknown) return const SizedBox.shrink();
                          
                          final isSelected = _selectedPhase == phase;
                          return FilterChip(
                            label: Text(_getPhaseTranslation(context, phase)),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedPhase = phase;
                              });
                            },
                            selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                            checkmarkColor: const Color(Constants.primaryColor),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Symptoms
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cycle_tracking.entry.symptoms'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _symptomOptions.map((symptom) {
                          final isSelected = _selectedSymptoms.contains(symptom);
                          return FilterChip(
                            label: Text(symptom),
                            selected: isSelected,
                            onSelected: (_) => _toggleSymptom(symptom),
                            selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                            checkmarkColor: const Color(Constants.primaryColor),
                          );
                        }).toList(),
                      ),
                      
                      if (_selectedSymptoms.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          context.tr('cycle_tracking.entry.symptom_severity'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        ..._selectedSymptoms.map((symptom) => _buildSymptomSeverityRow(context, symptom)),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Lifestyle tracking
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cycle_tracking.entry.lifestyle_tracking'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Sleep
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: context.tr('cycle_tracking.entry.sleep_hours'),
                          hintText: context.tr('cycle_tracking.entry.sleep_hint'),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          _sleepHours = double.tryParse(value);
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Water intake
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: context.tr('cycle_tracking.entry.water_intake'),
                          hintText: context.tr('cycle_tracking.entry.water_hint'),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _waterIntake = int.tryParse(value);
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Stress level
                      Text(
                        context.tr('cycle_tracking.entry.stress_level'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: (_stressLevel ?? 5).toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '${_stressLevel ?? 5}',
                        onChanged: (value) {
                          setState(() {
                            _stressLevel = value.round();
                          });
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Mood
                      Text(
                        context.tr('cycle_tracking.entry.mood'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _moodOptions.map((mood) {
                          final isSelected = _selectedMood == mood;
                          return FilterChip(
                            label: Text(mood),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedMood = isSelected ? null : mood;
                              });
                            },
                            selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                            checkmarkColor: const Color(Constants.primaryColor),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Activities
                      Text(
                        context.tr('cycle_tracking.entry.activities'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityOptions.map((activity) {
                          final isSelected = _selectedActivities.contains(activity);
                          return FilterChip(
                            label: Text(activity),
                            selected: isSelected,
                            onSelected: (_) => _toggleActivity(activity),
                            selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                            checkmarkColor: const Color(Constants.primaryColor),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Medication
                      SwitchListTile(
                        title: Text(context.tr('cycle_tracking.entry.took_medication')),
                        value: _tookMedication,
                        onChanged: (value) {
                          setState(() {
                            _tookMedication = value;
                          });
                        },
                      ),
                      
                      if (_tookMedication) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _medicationNotesController,
                          decoration: InputDecoration(
                            labelText: context.tr('cycle_tracking.entry.medication_notes'),
                            hintText: context.tr('cycle_tracking.entry.medication_hint'),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('cycle_tracking.entry.additional_notes'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: context.tr('cycle_tracking.entry.notes'),
                          hintText: context.tr('cycle_tracking.entry.notes_hint'),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(Constants.primaryColor),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    context.tr('cycle_tracking.entry.save_entry'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSymptomSeverityRow(BuildContext context, String symptom) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              symptom,
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: SymptomSeverity.values.map((severity) {
                final isSelected = _symptomSeverity[symptom] == severity;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _updateSymptomSeverity(symptom, severity),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(Constants.primaryColor)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getSeverityTranslation(context, severity),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getPhaseTranslation(BuildContext context, CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return context.tr('cycle_tracking.entry.phases.menstrual');
      case CyclePhase.follicular:
        return context.tr('cycle_tracking.entry.phases.follicular');
      case CyclePhase.ovulation:
        return context.tr('cycle_tracking.entry.phases.ovulation');
      case CyclePhase.luteal:
        return context.tr('cycle_tracking.entry.phases.luteal');
      case CyclePhase.unknown:
        return context.tr('cycle_tracking.entry.phases.unknown');
    }
  }

  String _getSeverityTranslation(BuildContext context, SymptomSeverity severity) {
    switch (severity) {
      case SymptomSeverity.none:
        return context.tr('cycle_tracking.entry.severity.none');
      case SymptomSeverity.mild:
        return context.tr('cycle_tracking.entry.severity.mild');
      case SymptomSeverity.moderate:
        return context.tr('cycle_tracking.entry.severity.moderate');
      case SymptomSeverity.severe:
        return context.tr('cycle_tracking.entry.severity.severe');
    }
  }
}





