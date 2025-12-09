import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:ovumate/utils/responsive_layout.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class EntryDetailScreen extends StatefulWidget {
  final CycleEntry entry;

  const EntryDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            DateFormat('MMM dd, yyyy').format(widget.entry.date),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editEntry,
            tooltip: 'Edit Entry',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEntry,
            tooltip: 'Delete Entry',
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveLayout.responsiveContainer(
          context: context,
          mobilePadding: const EdgeInsets.all(Constants.defaultPadding),
          tabletPadding: const EdgeInsets.all(Constants.largePadding),
          desktopPadding: const EdgeInsets.all(32.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhaseCard(),
                const SizedBox(height: 16),
                if (widget.entry.isPeriodDay) ...[
                  _buildPeriodCard(),
                  const SizedBox(height: 16),
                ],
                if (widget.entry.symptoms.isNotEmpty) ...[
                  _buildSymptomsCard(),
                  const SizedBox(height: 16),
                ],
                if (widget.entry.hasLifestyleData) ...[
                  _buildLifestyleCard(),
                  const SizedBox(height: 16),
                ],
                if (widget.entry.notes != null && widget.entry.notes!.isNotEmpty) ...[
                  _buildNotesCard(),
                  const SizedBox(height: 16),
                ],
                _buildActionsCard(),
                // Add bottom padding for better scrolling experience
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: ResponsiveLayout.isMobile(context) 
            ? const EdgeInsets.all(16) 
            : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPhaseIcon(),
                  color: _getPhaseColor(),
                  size: ResponsiveLayout.isMobile(context) ? 24 : 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cycle Phase',
                        style: ResponsiveTheme.getResponsiveCaptionStyle(
                          context,
                          color: const Color(Constants.textSecondaryColor),
                        ),
                      ),
                      Text(
                        widget.entry.phaseDisplayName,
                        style: ResponsiveTheme.getResponsiveTitleStyle(
                          context,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveLayout.isMobile(context) ? 12 : 16,
                    vertical: ResponsiveLayout.isMobile(context) ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getPhaseColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day ${_getCycleDay()}',
                    style: TextStyle(
                      color: _getPhaseColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveLayout.isMobile(context) ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 400) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Date',
                          DateFormat('EEEE, MMM dd, yyyy').format(widget.entry.date),
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          'Time',
                          DateFormat('HH:mm').format(widget.entry.createdAt),
                          Icons.access_time,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildInfoItem(
                        'Date',
                        DateFormat('EEEE, MMM dd, yyyy').format(widget.entry.date),
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoItem(
                        'Time',
                        DateFormat('HH:mm').format(widget.entry.createdAt),
                        Icons.access_time,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: ResponsiveLayout.isMobile(context) 
            ? const EdgeInsets.all(16) 
            : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bloodtype,
                  color: Color(Constants.periodColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Period Information',
                    style: ResponsiveTheme.getResponsiveTitleStyle(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.entry.periodFlow != null) ...[
              Row(
                children: [
                  const Text(
                    'Flow:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(Constants.textSecondaryColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.entry.periodFlowDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(Constants.textSecondaryColor),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(Constants.periodColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Period Day',
                    style: TextStyle(
                      color: Color(Constants.periodColor),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: ResponsiveLayout.isMobile(context) 
            ? const EdgeInsets.all(16) 
            : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medical_services,
                  color: Color(Constants.warningColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Symptoms',
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.entry.symptomSeverity.entries.map((entry) {
                    final symptom = entry.key;
                    final severity = entry.value;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.8,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(severity).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getSeverityColor(severity).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _translateSymptom(symptom),
                                style: TextStyle(
                                  color: _getSeverityColor(severity),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(severity),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                severity.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifestyleCard() {
    final lifestyleData = widget.entry.lifestyleData;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: ResponsiveLayout.isMobile(context) 
            ? const EdgeInsets.all(16) 
            : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Color(Constants.successColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Lifestyle Tracking',
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ResponsiveLayout.responsiveGrid(
              context: context,
              mobileCrossAxisCount: 1,
              tabletCrossAxisCount: 2,
              desktopCrossAxisCount: 3,
              children: [
                if (lifestyleData['sleep'] != null)
                  _buildLifestyleItem(
                    'Sleep',
                    '${lifestyleData['sleep']} hours',
                    Icons.bedtime,
                    const Color(Constants.primaryColor),
                  ),
                if (lifestyleData['water'] != null)
                  _buildLifestyleItem(
                    'Water Intake',
                    '${lifestyleData['water']} glasses',
                    Icons.water_drop,
                    const Color(Constants.fertileWindowColor),
                  ),
                if (lifestyleData['stress'] != null)
                  _buildLifestyleItem(
                    'Stress Level',
                    _getStressLevelText(lifestyleData['stress']),
                    Icons.psychology,
                    _getStressColor(lifestyleData['stress']),
                  ),
                if (lifestyleData['mood'] != null)
                  _buildLifestyleItem(
                    'Mood',
                    lifestyleData['mood'],
                    Icons.sentiment_satisfied,
                    const Color(Constants.successColor),
                  ),
                if (lifestyleData['activities'] != null)
                  _buildLifestyleItem(
                    'Activities',
                    lifestyleData['activities'].join(', '),
                    Icons.sports_soccer,
                    const Color(Constants.secondaryColor),
                  ),
                if (lifestyleData['medication'] != null)
                  _buildLifestyleItem(
                    'Medication',
                    lifestyleData['medication'],
                    Icons.medication,
                    const Color(Constants.warningColor),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: ResponsiveLayout.isMobile(context) 
            ? const EdgeInsets.all(16) 
            : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.note,
                  color: Color(Constants.textSecondaryColor),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Notes',
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                widget.entry.notes!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(Constants.textPrimaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.borderRadius),
      ),
      child: Padding(
        padding: ResponsiveLayout.isMobile(context) 
            ? const EdgeInsets.all(16) 
            : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: ResponsiveTheme.getResponsiveTitleStyle(
                context,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ResponsiveLayout.responsiveRow(
              context: context,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editEntry,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(Constants.primaryColor)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareEntry,
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(Constants.primaryColor),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              mobileChildren: [
                OutlinedButton.icon(
                  onPressed: _editEntry,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(Constants.primaryColor)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _shareEntry,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(Constants.primaryColor),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(Constants.textSecondaryColor),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(Constants.textSecondaryColor),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(Constants.textPrimaryColor),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLifestyleItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(Constants.textSecondaryColor),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(Constants.textPrimaryColor),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPhaseIcon() {
    switch (widget.entry.cyclePhase) {
      case CyclePhase.menstrual:
        return Icons.bloodtype;
      case CyclePhase.follicular:
        return Icons.eco;
      case CyclePhase.ovulation:
        return Icons.egg;
      case CyclePhase.luteal:
        return Icons.local_florist;
      case CyclePhase.unknown:
        return Icons.help;
      default:
        return Icons.help;
    }
  }

  Color _getPhaseColor() {
    switch (widget.entry.cyclePhase) {
      case CyclePhase.menstrual:
        return const Color(Constants.periodColor);
      case CyclePhase.follicular:
        return const Color(Constants.successColor);
      case CyclePhase.ovulation:
        return const Color(Constants.ovulationColor);
      case CyclePhase.luteal:
        return const Color(Constants.secondaryColor);
      case CyclePhase.unknown:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  int _getCycleDay() {
    // This is a simplified calculation - in a real app, you'd calculate based on the user's cycle
    final now = DateTime.now();
    final difference = now.difference(widget.entry.date).inDays;
    return (difference % 28) + 1; // Assuming 28-day cycle
  }

  Color _getSeverityColor(SymptomSeverity severity) {
    switch (severity) {
      case SymptomSeverity.none:
        return Colors.grey;
      case SymptomSeverity.mild:
        return const Color(Constants.successColor);
      case SymptomSeverity.moderate:
        return const Color(Constants.warningColor);
      case SymptomSeverity.severe:
        return const Color(Constants.errorColor);
      default:
        return Colors.grey;
    }
  }

  String _getStressLevelText(int level) {
    switch (level) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Moderate';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Unknown';
    }
  }

  Color _getStressColor(int level) {
    switch (level) {
      case 1:
      case 2:
        return const Color(Constants.successColor);
      case 3:
        return const Color(Constants.warningColor);
      case 4:
      case 5:
        return const Color(Constants.errorColor);
      default:
        return Colors.grey;
    }
  }

  void _editEntry() {
    // TODO: Navigate to edit entry screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
      ),
    );
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(Constants.errorColor),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    cycleProvider.deleteCycleEntry(widget.entry.id);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry deleted successfully'),
      ),
    );
  }

  void _shareEntry() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality coming soon!'),
      ),
    );
  }

  // Helper function to translate symptom names
  String _translateSymptom(String symptom) {
    // Map English symptom names to translation keys
    final symptomMap = {
      'Cramps': 'cycle_tracking.symptoms_options.cramps',
      'Bloating': 'cycle_tracking.symptoms_options.bloating',
      'Tender breasts': 'cycle_tracking.symptoms_options.tender_breasts',
      'Acne': 'cycle_tracking.symptoms_options.acne',
      'Food cravings': 'cycle_tracking.symptoms_options.food_cravings',
      'Headache': 'cycle_tracking.symptoms_options.headache',
      'Back pain': 'cycle_tracking.symptoms_options.back_pain',
      'Nausea': 'cycle_tracking.symptoms_options.nausea',
      'Dizziness': 'cycle_tracking.symptoms_options.dizziness',
      'Hot flashes': 'cycle_tracking.symptoms_options.hot_flashes',
      'Insomnia': 'cycle_tracking.symptoms_options.insomnia',
      'Anxiety': 'cycle_tracking.symptoms_options.anxiety',
      'Depression': 'cycle_tracking.symptoms_options.depression',
    };
    
    // Check if symptom matches a key in the map
    if (symptomMap.containsKey(symptom)) {
      return symptomMap[symptom]!.tr();
    }
    
    // If symptom is already a translation key, translate it
    if (symptom.startsWith('cycle_tracking.symptoms_options.')) {
      return symptom.tr();
    }
    
    // If symptom is already translated (contains non-ASCII characters), return as is
    // Otherwise, try to find a matching translation
    for (final entry in symptomMap.entries) {
      if (entry.value.tr() == symptom) {
        return symptom; // Already translated
      }
    }
    
    // Fallback: return symptom as is
    return symptom;
  }
}



