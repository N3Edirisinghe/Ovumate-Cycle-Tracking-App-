import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/utils/theme.dart';

class SleepWaterScreen extends StatefulWidget {
  const SleepWaterScreen({super.key});

  @override
  State<SleepWaterScreen> createState() => _SleepWaterScreenState();
}

class _SleepWaterScreenState extends State<SleepWaterScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.accentTeal.withOpacity(0.1),
              AppTheme.successGreen.withOpacity(0.1),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(),
              Expanded(
                child: Consumer<CycleProvider>(
                  builder: (context, cycleProvider, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                                                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                                                             children: [
                                   _buildSleepOverview(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildWaterIntakeAnalysis(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildSleepQualityChart(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildWaterTrends(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildLifestyleRecommendations(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildSleepTips(),
                                 ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
             margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.3),
            AppTheme.successGreen.withOpacity(0.3),
            AppTheme.primaryPink.withOpacity(0.2),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentTeal.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                                     'sleep_water.title'.tr(),
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 22,
                     fontWeight: FontWeight.w700,
                     letterSpacing: 0.4,
                   ),
                ),
                Text(
                                     'sleep_water.subtitle'.tr(),
                   style: TextStyle(
                     color: Colors.white.withOpacity(0.8),
                     fontSize: 13,
                     fontWeight: FontWeight.w500,
                   ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentTeal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.fitness_center,
              color: AppTheme.accentTeal,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepOverview(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    final sleepEntries = recentEntries.where((e) => e.sleepHours != null).toList();
    
    if (sleepEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentTeal.withOpacity(0.15),
              AppTheme.primaryPink.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.accentTeal.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bedtime,
                color: AppTheme.accentTeal,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'sleep_water.no_sleep_data'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'sleep_water.no_sleep_data_subtitle'.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final avgSleep = sleepEntries.map((e) => e.sleepHours!).reduce((a, b) => a + b) / sleepEntries.length;
    final sleepQuality = _getSleepQuality(avgSleep);
    final sleepTrend = _getSleepTrend(sleepEntries);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.15),
            AppTheme.primaryPink.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentTeal.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentTeal.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
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
                  color: AppTheme.accentTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.bedtime,
                  color: AppTheme.accentTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sleep_water.sleep_overview.title'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'sleep_water.sleep_overview.subtitle'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSleepStat(
                  'sleep_water.sleep_overview.average_sleep'.tr(),
                  '${avgSleep.toStringAsFixed(1)}h',
                  Icons.analytics,
                  AppTheme.accentTeal,
                ),
              ),
              Expanded(
                child: _buildSleepStat(
                  'sleep_water.sleep_overview.sleep_quality'.tr(),
                  sleepQuality,
                  Icons.star,
                  _getSleepQualityColor(sleepQuality),
                ),
              ),
              Expanded(
                child: _buildSleepStat(
                  'sleep_water.sleep_overview.trend'.tr(),
                  sleepTrend,
                  Icons.trending_up,
                  _getSleepTrendColor(sleepTrend),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          _buildSleepRecommendations(avgSleep),
        ],
      ),
    );
  }

  Widget _buildSleepStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getSleepQuality(double hours) {
    if (hours >= 8) return 'sleep_water.quality_levels.excellent'.tr();
    if (hours >= 7) return 'sleep_water.quality_levels.good'.tr();
    if (hours >= 6) return 'sleep_water.quality_levels.fair'.tr();
    return 'sleep_water.quality_levels.poor'.tr();
  }

  Color _getSleepQualityColor(String quality) {
    switch (quality) {
      case 'Excellent':
        return AppTheme.successGreen;
      case 'Good':
        return AppTheme.accentTeal;
      case 'Fair':
        return AppTheme.warningOrange;
      case 'Poor':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryPink;
    }
  }

  String _getSleepTrend(List<CycleEntry> entries) {
    if (entries.isEmpty) return 'sleep_water.trends.stable'.tr();
    if (entries.length < 2) return 'sleep_water.trends.stable'.tr();
    
    // Sort entries by date (most recent first)
    final sortedEntries = List<CycleEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Get recent entries (most recent 3)
    final recent = sortedEntries.take(3).where((e) => e.sleepHours != null).map((e) => e.sleepHours!).toList();
    
    // If we have at least 2 entries, calculate trend
    if (recent.length >= 2) {
      // Compare first (most recent) with average of rest
      final mostRecent = recent.first;
      final restAvg = recent.skip(1).reduce((a, b) => a + b) / (recent.length - 1);
      
      if (mostRecent > restAvg + 0.5) return 'sleep_water.trends.improving'.tr();
      if (mostRecent < restAvg - 0.5) return 'sleep_water.trends.declining'.tr();
      return 'sleep_water.trends.stable'.tr();
    }
    
    // If we have older entries, compare recent with older
    if (sortedEntries.length >= 4) {
      final older = sortedEntries.skip(3).take(3).where((e) => e.sleepHours != null).map((e) => e.sleepHours!).toList();
      if (recent.isNotEmpty && older.isNotEmpty) {
        final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
        final olderAvg = older.reduce((a, b) => a + b) / older.length;
        
        if (recentAvg > olderAvg + 0.5) return 'sleep_water.trends.improving'.tr();
        if (recentAvg < olderAvg - 0.5) return 'sleep_water.trends.declining'.tr();
        return 'sleep_water.trends.stable'.tr();
      }
    }
    
    return 'sleep_water.trends.stable'.tr();
  }

  Color _getSleepTrendColor(String trend) {
    // Check translated strings
    if (trend == 'sleep_water.trends.improving'.tr() || trend.contains('Improving') || trend.contains('improving')) {
      return AppTheme.successGreen;
    }
    if (trend == 'sleep_water.trends.declining'.tr() || trend.contains('Declining') || trend.contains('declining')) {
      return AppTheme.errorRed;
    }
    if (trend == 'sleep_water.trends.stable'.tr() || trend.contains('Stable') || trend.contains('stable')) {
      return AppTheme.accentTeal;
    }
    return AppTheme.primaryPink;
  }

  Widget _buildSleepRecommendations(double avgSleep) {
    String recommendation;
    Color color;
    
    if (avgSleep >= 8) {
      recommendation = 'sleep_water.sleep_recommendations.excellent'.tr();
      color = AppTheme.successGreen;
    } else if (avgSleep >= 7) {
      recommendation = 'sleep_water.sleep_recommendations.good'.tr();
      color = AppTheme.accentTeal;
    } else if (avgSleep >= 6) {
      recommendation = 'sleep_water.sleep_recommendations.fair'.tr();
      color = AppTheme.warningOrange;
    } else {
      recommendation = 'sleep_water.sleep_recommendations.poor'.tr();
      color = AppTheme.errorRed;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeAnalysis(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    final waterEntries = recentEntries.where((e) => e.waterIntake != null).toList();
    
    if (waterEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.successGreen.withOpacity(0.15),
              AppTheme.accentTeal.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.successGreen.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.water_drop,
                color: AppTheme.successGreen,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'sleep_water.no_water_data'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'sleep_water.no_water_data_subtitle'.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final avgWater = waterEntries.map((e) => e.waterIntake!).reduce((a, b) => a + b) / waterEntries.length;
    final waterQuality = _getWaterQuality(avgWater);
    final waterTrend = _getWaterTrend(waterEntries);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successGreen.withOpacity(0.15),
            AppTheme.accentTeal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: AppTheme.successGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'sleep_water.water_overview.title'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'sleep_water.water_overview.subtitle'.tr(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildWaterStat(
                  'sleep_water.water_overview.average_intake'.tr(),
                  '${(avgWater / 1000).toStringAsFixed(1)}L',
                  Icons.analytics,
                  AppTheme.successGreen,
                ),
              ),
              Expanded(
                child: _buildWaterStat(
                  'sleep_water.water_overview.hydration_level'.tr(),
                  waterQuality,
                  Icons.star,
                  _getWaterQualityColor(waterQuality),
                ),
              ),
              Expanded(
                child: _buildWaterStat(
                  'sleep_water.water_overview.trend'.tr(),
                  waterTrend,
                  Icons.trending_up,
                  _getWaterTrendColor(waterTrend),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          _buildWaterRecommendations(avgWater),
        ],
      ),
    );
  }

  Widget _buildWaterStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getWaterQuality(double ml) {
    if (ml >= 2500) return 'sleep_water.quality_levels.excellent'.tr();
    if (ml >= 2000) return 'sleep_water.quality_levels.good'.tr();
    if (ml >= 1500) return 'sleep_water.quality_levels.fair'.tr();
    return 'sleep_water.quality_levels.low'.tr();
  }

  Color _getWaterQualityColor(String quality) {
    switch (quality) {
      case 'Excellent':
        return AppTheme.successGreen;
      case 'Good':
        return AppTheme.accentTeal;
      case 'Fair':
        return AppTheme.warningOrange;
      case 'Low':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryPink;
    }
  }

  String _getWaterTrend(List<CycleEntry> entries) {
    if (entries.isEmpty) return 'sleep_water.trends.stable'.tr();
    if (entries.length < 2) return 'sleep_water.trends.stable'.tr();
    
    // Sort entries by date (most recent first)
    final sortedEntries = List<CycleEntry>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    // Get recent entries (most recent 3)
    final recent = sortedEntries.take(3).where((e) => e.waterIntake != null).map((e) => e.waterIntake!).toList();
    
    // If we have at least 2 entries, calculate trend
    if (recent.length >= 2) {
      // Compare first (most recent) with average of rest
      final mostRecent = recent.first;
      final restAvg = recent.skip(1).reduce((a, b) => a + b) / (recent.length - 1);
      
      if (mostRecent > restAvg + 200) return 'sleep_water.trends.improving'.tr();
      if (mostRecent < restAvg - 200) return 'sleep_water.trends.declining'.tr();
      return 'sleep_water.trends.stable'.tr();
    }
    
    // If we have older entries, compare recent with older
    if (sortedEntries.length >= 4) {
      final older = sortedEntries.skip(3).take(3).where((e) => e.waterIntake != null).map((e) => e.waterIntake!).toList();
      if (recent.isNotEmpty && older.isNotEmpty) {
        final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
        final olderAvg = older.reduce((a, b) => a + b) / older.length;
        
        if (recentAvg > olderAvg + 200) return 'sleep_water.trends.improving'.tr();
        if (recentAvg < olderAvg - 200) return 'sleep_water.trends.declining'.tr();
        return 'sleep_water.trends.stable'.tr();
      }
    }
    
    return 'sleep_water.trends.stable'.tr();
  }

  Color _getWaterTrendColor(String trend) {
    // Check translated strings
    if (trend == 'sleep_water.trends.improving'.tr() || trend.contains('Improving') || trend.contains('improving')) {
      return AppTheme.successGreen;
    }
    if (trend == 'sleep_water.trends.declining'.tr() || trend.contains('Declining') || trend.contains('declining')) {
      return AppTheme.errorRed;
    }
    if (trend == 'sleep_water.trends.stable'.tr() || trend.contains('Stable') || trend.contains('stable')) {
      return AppTheme.accentTeal;
    }
    return AppTheme.primaryPink;
  }

  Widget _buildWaterRecommendations(double avgWater) {
    String recommendation;
    Color color;
    
    if (avgWater >= 2500) {
      recommendation = 'sleep_water.water_recommendations.excellent'.tr();
      color = AppTheme.successGreen;
    } else if (avgWater >= 2000) {
      recommendation = 'sleep_water.water_recommendations.good'.tr();
      color = AppTheme.accentTeal;
    } else if (avgWater >= 1500) {
      recommendation = 'sleep_water.water_recommendations.moderate'.tr();
      color = AppTheme.warningOrange;
    } else {
      recommendation = 'sleep_water.water_recommendations.low'.tr();
      color = AppTheme.errorRed;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityChart(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries
        .where((e) => e.sleepHours != null)
        .take(7)
        .toList();
    
    // Debug: Print the count
    print('Sleep entries found: ${recentEntries.length}');
    
    final hasData = recentEntries.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        if (hasData) {
          _showSleepChartDialog(recentEntries);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.secondaryPurple.withOpacity(0.15),
              AppTheme.accentTeal.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.secondaryPurple.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.bar_chart,
                color: AppTheme.secondaryPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sleep_water.sleep_overview.chart_title'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasData 
                        ? 'sleep_water.sleep_overview.chart_subtitle'.tr()
                        : 'sleep_water.no_chart_data_sleep'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (hasData)
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.secondaryPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterTrends(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries
        .where((e) => e.waterIntake != null)
        .take(7)
        .toList();
    
    // Debug: Print the count
    print('Water entries found: ${recentEntries.length}');
    
    final hasData = recentEntries.isNotEmpty;
    
    return GestureDetector(
      onTap: () {
        if (hasData) {
          _showWaterChartDialog(recentEntries);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryPink.withOpacity(0.15),
              AppTheme.successGreen.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryPink.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.trending_up,
                color: AppTheme.successGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'sleep_water.water_overview.chart_title'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasData 
                        ? 'sleep_water.water_overview.chart_subtitle'.tr()
                        : 'sleep_water.no_chart_data_water'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (hasData)
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.successGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Show Sleep Chart Dialog
  void _showSleepChartDialog(List<CycleEntry> entries) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundDark,
                AppTheme.secondaryPurple.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.secondaryPurple.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: AppTheme.secondaryPurple, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'sleep_water.sleep_overview.chart_title'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'sleep_water.dialog_sleep_subtitle'.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: _buildSleepBarChart(entries),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show Water Chart Dialog
  void _showWaterChartDialog(List<CycleEntry> entries) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundDark,
                AppTheme.successGreen.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.successGreen.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: AppTheme.successGreen, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'sleep_water.water_overview.chart_title'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'sleep_water.dialog_water_subtitle'.tr(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: _buildWaterBarChart(entries),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifestyleRecommendations(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    final sleepEntries = recentEntries.where((e) => e.sleepHours != null).toList();
    final waterEntries = recentEntries.where((e) => e.waterIntake != null).toList();
    
    if (sleepEntries.isEmpty && waterEntries.isEmpty) return const SizedBox.shrink();
    
    final recommendations = <String>[];
    
    if (sleepEntries.isNotEmpty) {
      final avgSleep = sleepEntries.map((e) => e.sleepHours!).reduce((a, b) => a + b) / sleepEntries.length;
      if (avgSleep < 7) {
        recommendations.add('sleep_water.lifestyle_sleep_tip'.tr());
      }
    }
    
    if (waterEntries.isNotEmpty) {
      final avgWater = waterEntries.map((e) => e.waterIntake!).reduce((a, b) => a + b) / waterEntries.length;
      if (avgWater < 2000) {
        recommendations.add('sleep_water.lifestyle_water_tip'.tr());
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('sleep_water.lifestyle_great'.tr());
    }
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningOrange.withOpacity(0.15),
            AppTheme.successGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.warningOrange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.recommend,
                  color: AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'sleep_water.lifestyle_recommendations'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...recommendations.map((recommendation) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.warningOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  Widget _buildSleepTips() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPink.withOpacity(0.15),
            AppTheme.accentTeal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: AppTheme.primaryPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'sleep_water.sleep_tips_title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ..._getSleepAndWaterTips().map((tip) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  List<String> _getSleepAndWaterTips() {
    final tips = <String>[];
    tips.addAll([
      'sleep_water.sleep_tips.tip1'.tr(),
      'sleep_water.sleep_tips.tip2'.tr(),
      'sleep_water.sleep_tips.tip3'.tr(),
      'sleep_water.sleep_tips.tip4'.tr(),
      'sleep_water.sleep_tips.tip5'.tr(),
      'sleep_water.sleep_tips.tip6'.tr(),
      'sleep_water.sleep_tips.tip7'.tr(),
      'sleep_water.sleep_tips.tip8'.tr(),
      'sleep_water.sleep_tips.tip9'.tr(),
      'sleep_water.sleep_tips.tip10'.tr(),
    ]);
    return tips;
  }

  Widget _buildSleepBarChart(List<CycleEntry> entries) {
    // Find the maximum sleep hours for scaling
    final maxSleep = entries.map((e) => e.sleepHours!).reduce((a, b) => a > b ? a : b);
    final maxBarWidth = 200.0;
    
    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final cycleEntry = entry.value;
        final sleepHours = cycleEntry.sleepHours!;
        final quality = _getSleepQuality(sleepHours.toDouble());
        final color = _getSleepQualityColor(quality);
        final barWidth = (sleepHours / maxSleep) * maxBarWidth;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${cycleEntry.date.day}/${cycleEntry.date.month}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          height: 32,
                          width: barWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                color,
                                color.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${sleepHours.toStringAsFixed(1)}h',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      quality.split('.').last,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWaterBarChart(List<CycleEntry> entries) {
    // Find the maximum water intake for scaling
    final maxWater = entries.map((e) => e.waterIntake!).reduce((a, b) => a > b ? a : b);
    final maxBarWidth = 200.0;
    
    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final cycleEntry = entry.value;
        final waterIntake = cycleEntry.waterIntake!;
        final quality = _getWaterQuality(waterIntake.toDouble());
        final color = _getWaterQualityColor(quality);
        final barWidth = (waterIntake / maxWater) * maxBarWidth;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${cycleEntry.date.day}/${cycleEntry.date.month}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          height: 32,
                          width: barWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                color,
                                color.withOpacity(0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${(waterIntake / 1000).toStringAsFixed(1)}L',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      quality.split('.').last,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
