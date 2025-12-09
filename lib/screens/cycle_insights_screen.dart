import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/utils/theme.dart';
import 'dart:math';

class CycleInsightsScreen extends StatefulWidget {
  const CycleInsightsScreen({super.key});

  @override
  State<CycleInsightsScreen> createState() => _CycleInsightsScreenState();
}

class _CycleInsightsScreenState extends State<CycleInsightsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'cycle_tracking.insights.title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppTheme.primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CycleProvider>(
        builder: (context, cycleProvider, child) {
          if (cycleProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryPink,
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                // Overview Section
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildOverviewSection(cycleProvider),
                  ),
                ),

                // Cycle Trends Section
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildCycleTrendsSection(cycleProvider),
                  ),
                ),

                // Symptom Analysis Section
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildSymptomAnalysisSection(cycleProvider),
                  ),
                ),

                // Lifestyle Insights Section
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLifestyleInsightsSection(cycleProvider),
                  ),
                ),

                // Predictions Section
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildPredictionsSection(cycleProvider),
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection(CycleProvider cycleProvider) {
    final insights = cycleProvider.cycleInsights;
    final regularity = insights['cycleRegularity'] as double;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPink,
            AppTheme.secondaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'cycle_tracking.insights.overview.title'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'cycle_tracking.insights.overview.regularity'.tr(),
                  '${regularity.toStringAsFixed(0)}%',
                  Icons.trending_up,
                  _getRegularityColor(regularity),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'cycle_tracking.insights.overview.avg_cycle'.tr(),
                  '${cycleProvider.averageCycleLength} days',
                  Icons.calendar_today,
                  AppTheme.accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'cycle_tracking.insights.overview.avg_period'.tr(),
                  '${cycleProvider.averagePeriodLength} days',
                  Icons.water_drop,
                  AppTheme.successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOverviewCard(
                  'cycle_tracking.insights.overview.cycles_tracked'.tr(),
                  '${cycleProvider.cyclesTracked}',
                  Icons.analytics,
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleTrendsSection(CycleProvider cycleProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.insights.trends.title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildTrendChart(cycleProvider),
                const SizedBox(height: 20),
                _buildTrendInsights(cycleProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(CycleProvider cycleProvider) {
    final periodEntries = cycleProvider.periodEntries;
    if (periodEntries.length < 2) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryPink,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'cycle_tracking.insights.trends.no_data'.tr(),
                style: TextStyle(
                  color: AppTheme.primaryPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate cycle lengths
    List<int> cycleLengths = [];
    for (int i = 0; i < periodEntries.length - 1; i++) {
      final days = periodEntries[i].date
          .difference(periodEntries[i + 1].date)
          .inDays
          .abs();
      cycleLengths.add(days);
    }

    return Container(
      height: 200,
      child: CustomPaint(
        painter: CycleTrendPainter(cycleLengths),
        child: Container(),
      ),
    );
  }

  Widget _buildTrendInsights(CycleProvider cycleProvider) {
    final periodEntries = cycleProvider.periodEntries;
    if (periodEntries.length < 2) {
      return const SizedBox.shrink();
    }

    // Calculate trend insights
    List<int> cycleLengths = [];
    for (int i = 0; i < periodEntries.length - 1; i++) {
      final days = periodEntries[i].date
          .difference(periodEntries[i + 1].date)
          .inDays
          .abs();
      cycleLengths.add(days);
    }

    final average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    final minValue = cycleLengths.reduce((a, b) => a < b ? a : b);
    final maxValue = cycleLengths.reduce((a, b) => a > b ? a : b);
    final variance = cycleLengths
        .map((length) => (length - average) * (length - average))
        .reduce((a, b) => a + b) / cycleLengths.length;
    final standardDeviation = sqrt(variance);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'cycle_tracking.insights.trends.shortest'.tr(),
                '$minValue days',
                Icons.trending_down,
                AppTheme.warningOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'cycle_tracking.insights.trends.longest'.tr(),
                '$maxValue days',
                Icons.trending_up,
                AppTheme.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'cycle_tracking.insights.trends.variation'.tr(),
                '${standardDeviation.toStringAsFixed(1)} days',
                Icons.analytics,
                AppTheme.accentTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'cycle_tracking.insights.trends.consistency'.tr(),
                standardDeviation < 3 ? 'cycle_tracking.insights.trends.high'.tr() : standardDeviation < 7 ? 'cycle_tracking.insights.trends.medium'.tr() : 'cycle_tracking.insights.trends.low'.tr(),
                Icons.straighten,
                _getConsistencyColor(standardDeviation),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSymptomAnalysisSection(CycleProvider cycleProvider) {
    final symptomData = _analyzeSymptoms(cycleProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.insights.symptoms.title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                if (symptomData.isEmpty)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            color: AppTheme.successGreen,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'cycle_tracking.insights.symptoms.no_data'.tr(),
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...symptomData.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.successGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getSymptomIcon(entry.key),
                            color: AppTheme.successGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'cycle_tracking.insights.symptoms.frequency'.tr(args: ['${entry.value['frequency']}']),
                                  style: TextStyle(
                                    color: Color(0xFF5D6D7E),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${entry.value['severity']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleInsightsSection(CycleProvider cycleProvider) {
    final lifestyleData = _analyzeLifestyle(cycleProvider);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.insights.lifestyle.title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildLifestyleCard(
                        'cycle_tracking.insights.lifestyle.avg_sleep'.tr(),
                        '${lifestyleData['avgSleep']?.toStringAsFixed(1) ?? 'N/A'} hrs',
                        Icons.bedtime,
                        AppTheme.accentTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLifestyleCard(
                        'cycle_tracking.insights.lifestyle.avg_water'.tr(),
                        '${lifestyleData['avgWater']?.toStringAsFixed(0) ?? 'N/A'} ml',
                        Icons.water_drop,
                        AppTheme.accentTeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildLifestyleCard(
                        'cycle_tracking.insights.lifestyle.avg_stress'.tr(),
                        '${lifestyleData['avgStress']?.toStringAsFixed(1) ?? 'N/A'}/10',
                        Icons.psychology,
                        AppTheme.warningOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLifestyleCard(
                        'cycle_tracking.insights.lifestyle.common_mood'.tr(),
                        lifestyleData['commonMood'] ?? 'N/A',
                        Icons.mood,
                        AppTheme.primaryPink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsSection(CycleProvider cycleProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.insights.predictions.title'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                if (cycleProvider.nextPeriodStart != null)
                  _buildPredictionCard(
                    'cycle_tracking.insights.predictions.next_period'.tr(),
                    cycleProvider.nextPeriodStart!,
                    Icons.calendar_today,
                    AppTheme.primaryPink,
                  ),
                if (cycleProvider.nextOvulationDate != null) ...[
                  const SizedBox(height: 12),
                  _buildPredictionCard(
                    'cycle_tracking.insights.predictions.next_ovulation'.tr(),
                    cycleProvider.nextOvulationDate!,
                    Icons.egg,
                    AppTheme.secondaryPurple,
                  ),
                ],
                const SizedBox(height: 12),
                _buildPredictionCard(
                  'cycle_tracking.insights.predictions.current_phase'.tr(),
                  DateTime.now(),
                  Icons.timeline,
                  AppTheme.accentTeal,
                  subtitle: cycleProvider.currentPhase.toString().split('.').last,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF5D6D7E),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleCard(String title, String value, IconData icon, Color color) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF5D6D7E),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(String title, DateTime date, IconData icon, Color color, {String? subtitle}) {
    final daysUntil = date.difference(DateTime.now()).inDays;
    final isPast = daysUntil < 0;
    final isToday = daysUntil == 0;
    
    String timeText;
    if (isToday) {
      timeText = 'cycle_tracking.insights.predictions.today'.tr();
    } else if (isPast) {
      timeText = 'cycle_tracking.insights.predictions.days_ago'.tr(args: ['${daysUntil.abs()}']);
    } else {
      timeText = 'cycle_tracking.insights.predictions.in_days'.tr(args: ['$daysUntil']);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Color(0xFF5D6D7E),
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getRegularityColor(double regularity) {
    if (regularity >= 80) return AppTheme.successGreen;
    if (regularity >= 60) return AppTheme.warningOrange;
    return AppTheme.primaryPink;
  }

  Color _getConsistencyColor(double standardDeviation) {
    if (standardDeviation < 3) return AppTheme.successGreen;
    if (standardDeviation < 7) return AppTheme.warningOrange;
    return AppTheme.primaryPink;
  }

  IconData _getSymptomIcon(String symptom) {
    switch (symptom.toLowerCase()) {
      case 'cramps':
        return Icons.health_and_safety;
      case 'fatigue':
        return Icons.bedtime;
      case 'bloating':
        return Icons.water_drop;
      case 'mood swings':
        return Icons.mood;
      case 'headache':
        return Icons.medical_services;
      default:
        return Icons.health_and_safety;
    }
  }

  Map<String, Map<String, dynamic>> _analyzeSymptoms(CycleProvider cycleProvider) {
    final entries = cycleProvider.cycleEntries;
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
          'severity': _getSeverityText(avgSeverity),
        };
      }
    }

    return result;
  }

  String _getSeverityText(double severity) {
    if (severity <= 1.5) return 'cycle_tracking.insights.symptoms.severity.mild'.tr();
    if (severity <= 2.5) return 'cycle_tracking.insights.symptoms.severity.moderate'.tr();
    return 'cycle_tracking.insights.symptoms.severity.severe'.tr();
  }

  Map<String, dynamic> _analyzeLifestyle(CycleProvider cycleProvider) {
    final entries = cycleProvider.cycleEntries;
    if (entries.isEmpty) return {};

    double totalSleep = 0;
    double totalWater = 0;
    double totalStress = 0;
    Map<String, int> moodCounts = {};
    int validEntries = 0;

    for (final entry in entries) {
      if (entry.sleepHours != null) {
        totalSleep += entry.sleepHours!;
        validEntries++;
      }
      if (entry.waterIntake != null) {
        totalWater += entry.waterIntake!;
      }
      if (entry.stressLevel != null) {
        totalStress += entry.stressLevel!;
      }
      if (entry.mood != null && entry.mood!.isNotEmpty) {
        moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
      }
    }

    return {
      'avgSleep': validEntries > 0 ? totalSleep / validEntries : null,
      'avgWater': validEntries > 0 ? totalWater / validEntries : null,
      'avgStress': validEntries > 0 ? totalStress / validEntries : null,
      'commonMood': moodCounts.isNotEmpty 
          ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }
}

// Custom painter for cycle trend chart
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
      ..color = AppTheme.primaryPink.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final minLength = cycleLengths.reduce((a, b) => a < b ? a : b);
    final maxLength = cycleLengths.reduce((a, b) => a > b ? a : b);
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
