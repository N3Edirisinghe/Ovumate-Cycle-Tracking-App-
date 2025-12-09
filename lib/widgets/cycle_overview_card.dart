import 'package:flutter/material.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/utils/constants.dart';

class CycleOverviewCard extends StatelessWidget {
  final CyclePhase currentPhase;
  final int averageCycleLength;
  final int averagePeriodLength;
  final int cyclesTracked;

  const CycleOverviewCard({
    super.key,
    required this.currentPhase,
    required this.averageCycleLength,
    required this.averagePeriodLength,
    required this.cyclesTracked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getPhaseIcon(),
                  color: _getPhaseColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Phase',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currentPhase.phaseDisplayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPhaseColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_getPhaseDay()}',
                    style: TextStyle(
                      color: _getPhaseColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Cycle Length',
                    '$averageCycleLength days',
                    Icons.calendar_today,
                    const Color(Constants.primaryColor),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Period Length',
                    '$averagePeriodLength days',
                    Icons.bloodtype,
                    const Color(Constants.periodColor),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Cycles Tracked',
                    '$cyclesTracked',
                    Icons.trending_up,
                    const Color(Constants.successColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  IconData _getPhaseIcon() {
    switch (currentPhase) {
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
    }
  }

  Color _getPhaseColor() {
    switch (currentPhase) {
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
    }
  }

  String _getPhaseDay() {
    switch (currentPhase) {
      case CyclePhase.menstrual:
        return 'Day 1-5';
      case CyclePhase.follicular:
        return 'Day 6-13';
      case CyclePhase.ovulation:
        return 'Day 14';
      case CyclePhase.luteal:
        return 'Day 15-28';
      case CyclePhase.unknown:
        return 'Unknown';
    }
  }
}


