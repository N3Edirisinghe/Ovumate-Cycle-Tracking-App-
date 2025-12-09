import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:ovumate/utils/whatsapp_share.dart';

class LifestyleScreen extends StatefulWidget {
  const LifestyleScreen({super.key});

  @override
  State<LifestyleScreen> createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  DateTime _selectedDate = DateTime.now();
  int _sleepHours = 8;
  int _waterIntake = 2000;
  int _stressLevel = 5;
  String _selectedMood = 'lifestyle.mood.options.happy'.tr();
  final List<String> _selectedActivities = [];
  bool _tookMedication = false;
  final _medicationNotesController = TextEditingController();

  final List<String> _moodOptions = [
    'lifestyle.mood.options.happy'.tr(),
    'lifestyle.mood.options.calm'.tr(),
    'lifestyle.mood.options.energetic'.tr(),
    'lifestyle.mood.options.irritable'.tr(),
    'lifestyle.mood.options.anxious'.tr(),
    'lifestyle.mood.options.sad'.tr(),
    'lifestyle.mood.options.stressed'.tr(),
    'lifestyle.mood.options.focused'.tr(),
    'lifestyle.mood.options.tired'.tr(),
    'lifestyle.mood.options.excited'.tr()
  ];

  final List<String> _activityOptions = [
    'lifestyle.activities.options.exercise'.tr(),
    'lifestyle.activities.options.yoga'.tr(),
    'lifestyle.activities.options.meditation'.tr(),
    'lifestyle.activities.options.reading'.tr(),
    'lifestyle.activities.options.socializing'.tr(),
    'lifestyle.activities.options.work'.tr(),
    'lifestyle.activities.options.rest'.tr(),
    'lifestyle.activities.options.shopping'.tr(),
    'lifestyle.activities.options.cooking'.tr(),
    'lifestyle.activities.options.cleaning'.tr()
  ];

  @override
  void dispose() {
    _medicationNotesController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text('lifestyle.title'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis,),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Next Period Date Card
            Consumer<CycleProvider>(
              builder: (context, cycleProvider, child) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryPink,
                          AppTheme.secondaryPurple,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'lifestyle.next_period.title'.tr(),
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (cycleProvider.nextPeriodStart != null) ...[
                          Text(
                            DateFormat('EEEE, MMMM d').format(cycleProvider.nextPeriodStart!),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'lifestyle.next_period.days_away'.tr(args: ['${DateTime.now().difference(cycleProvider.nextPeriodStart!).inDays}']),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white, // Darker white for better visibility
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          Text(
                            'lifestyle.next_period.not_available'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white, // Darker white for better visibility
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'lifestyle.next_period.track_more'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white, // Darker white for better visibility
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Date Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lifestyle.date.title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // White text color for better visibility
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
                            Expanded(
                              child: Text(
                                DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white, // White text color for better visibility
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
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

            // Sleep Tracking
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lifestyle.sleep.title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // White text color for better visibility
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _sleepHours.toDouble(),
                            min: 0,
                            max: 12,
                            divisions: 12,
                            label: '$_sleepHours hours',
                            onChanged: (value) {
                              setState(() {
                                _sleepHours = value.round();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'lifestyle.sleep.hours'.tr(args: ['$_sleepHours']),
                            style: TextStyle(
                              color: AppTheme.primaryPink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Water Intake
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lifestyle.water.title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // White text color for better visibility
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _waterIntake.toDouble(),
                            min: 0,
                            max: 4000,
                            divisions: 40,
                            label: '$_waterIntake ml',
                            onChanged: (value) {
                              setState(() {
                                _waterIntake = value.round();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'lifestyle.water.ml'.tr(args: ['$_waterIntake']),
                            style: TextStyle(
                              color: AppTheme.accentTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stress Level
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lifestyle.stress.title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // White text color for better visibility
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _stressLevel.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$_stressLevel',
                            onChanged: (value) {
                              setState(() {
                                _stressLevel = value.round();
                              });
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.warningOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'lifestyle.stress.level'.tr(args: ['$_stressLevel']),
                            style: TextStyle(
                              color: AppTheme.warningOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mood Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lifestyle.mood.title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // White text color for better visibility
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
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
                              _selectedMood = mood;
                            });
                          },
                          selectedColor: AppTheme.primaryPink.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryPink,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Activities
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'lifestyle.activities.title'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white, // White text color for better visibility
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                          selectedColor: AppTheme.secondaryPurple.withOpacity(0.2),
                          checkmarkColor: AppTheme.secondaryPurple,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Medication
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text('lifestyle.medication.title'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis,),
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
                          labelText: 'lifestyle.medication.notes.label'.tr(),
                          hintText: 'lifestyle.medication.notes.hint'.tr(),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

                                    // Save and Share Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // TODO: Save lifestyle data
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('lifestyle.messages.save_success'.tr()),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryPink,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: Text(
                                    'lifestyle.buttons.save'.tr(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () => _shareLifestyleData(),
                                icon: const Icon(Icons.share),
                                label: Text('lifestyle.buttons.share'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis,),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentTeal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                ),
                              ),
                            ),
                          ],
                        ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _shareLifestyleData() async {
    final success = await WhatsAppShare.shareLifestyleData(
      sleepHours: _sleepHours,
      waterIntake: _waterIntake,
      mood: _selectedMood,
      activities: _selectedActivities,
      stressLevel: _stressLevel,
    );
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lifestyle.messages.share_error'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('lifestyle.messages.share_success'.tr()),
          backgroundColor: AppTheme.accentTeal,
        ),
      );
    }
  }
}
