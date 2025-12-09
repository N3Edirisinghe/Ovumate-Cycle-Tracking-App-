import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/utils/theme.dart';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class CycleStatisticsWidget extends StatelessWidget {
  const CycleStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, child) {
        if (cycleProvider.isLoading) {
    return Container(
            height: 200,
      decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
        border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryPink,
        ),
      ),
    );
  }

        final trends = cycleProvider.cycleTrends;
    final insights = cycleProvider.cycleInsights;
    
        if (trends.isEmpty) {
          return _buildEmptyState();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: AppTheme.primaryPink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
              Text(
                    'cycle_tracking.statistics.title'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A252F),
                ),
              ),
            ],
          ),
              const SizedBox(height: 16),
              
              // Regularity Score
              _buildStatCard(
                'cycle_tracking.statistics.regularity_score'.tr(),
                '${(insights['cycleRegularity'] as double).toStringAsFixed(0)}%',
                Icons.straighten,
                _getRegularityColor(insights['cycleRegularity'] as double),
                'cycle_tracking.statistics.regularity_description'.tr(),
              ),
              
              const SizedBox(height: 12),
              
              // Cycle Length Stats
              Row(
      children: [
                  Expanded(
                    child: _buildStatCard(
          'cycle_tracking.statistics.average_cycle'.tr(),
                      '${trends['average']?.toStringAsFixed(0) ?? 'N/A'} ${'cycle_tracking.statistics.days'.tr()}',
          Icons.calendar_today,
                      AppTheme.accentTeal,
                      'cycle_tracking.statistics.average_cycle_description'.tr(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'cycle_tracking.statistics.variation'.tr(),
                      '${trends['standardDeviation']?.toStringAsFixed(1) ?? 'N/A'} ${'cycle_tracking.statistics.days'.tr()}',
                      Icons.analytics,
                      AppTheme.warningOrange,
                      'cycle_tracking.statistics.variation_description'.tr(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Range Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'cycle_tracking.statistics.shortest'.tr(),
                      '${trends['min'] ?? 'N/A'} ${'cycle_tracking.statistics.days'.tr()}',
                      Icons.trending_down,
                      AppTheme.successGreen,
                      'cycle_tracking.statistics.shortest_description'.tr(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'cycle_tracking.statistics.longest'.tr(),
                      '${trends['max'] ?? 'N/A'} ${'cycle_tracking.statistics.days'.tr()}',
          Icons.trending_up,
                      AppTheme.primaryPink,
                      'cycle_tracking.statistics.longest_description'.tr(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                color: AppTheme.primaryPink,
            size: 32,
              ),
            ),
            const SizedBox(height: 16),
                      Text(
              'Track more cycles to see statistics',
              style: TextStyle(
                color: Color(0xFF5D6D7E),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least 2 period entries to get insights',
              style: TextStyle(
                color: Color(0xFF5D6D7E),
                fontSize: 14,
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF1A252F),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF5D6D7E),
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getRegularityColor(double regularity) {
    if (regularity >= 80) return AppTheme.successGreen;
    if (regularity >= 60) return AppTheme.warningOrange;
    return AppTheme.primaryPink;
  }
}

class CycleTrendChart extends StatelessWidget {
  final List<int> cycleLengths;
  final double height;

  const CycleTrendChart({
    super.key,
    required this.cycleLengths,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (cycleLengths.length < 2) {
    return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.trending_up,
                color: AppTheme.primaryPink,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Need more data for trend chart',
                style: const TextStyle(
                  color: AppTheme.primaryPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cycle Length Trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A252F),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: CycleTrendPainter(cycleLengths),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class CycleTrendPainter extends CustomPainter {
  final List<int> cycleLengths;

  CycleTrendPainter(this.cycleLengths);

  @override
  void paint(Canvas canvas, Size size) {
    if (cycleLengths.isEmpty) return;

    final paint = Paint()
      ..color = AppTheme.primaryPink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppTheme.primaryPink.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final minLength = cycleLengths.reduce(min);
    final maxLength = cycleLengths.reduce(max);
    final range = maxLength - minLength;
    
    if (range == 0) return;

    final points = <Offset>[];
    final stepX = size.width / (cycleLengths.length - 1);
    
    for (int i = 0; i < cycleLengths.length; i++) {
      final x = i * stepX;
      final y = size.height - ((cycleLengths[i] - minLength) / range * size.height);
      points.add(Offset(x, y));
    }

    // Draw filled area
    final path = Path();
    path.moveTo(points.first.dx, size.height);
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }

    // Draw points
    final pointPaint = Paint()
      ..color = AppTheme.primaryPink
      ..style = PaintingStyle.fill;
    
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
    }

    // Draw labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    for (int i = 0; i < points.length; i++) {
      textPainter.text = TextSpan(
        text: '${cycleLengths[i]}',
        style: TextStyle(
          color: AppTheme.primaryPink,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, points[i].dy - 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}