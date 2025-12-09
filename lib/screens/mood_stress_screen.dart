import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/utils/theme.dart';

class MoodStressScreen extends StatefulWidget {
  const MoodStressScreen({super.key});

  @override
  State<MoodStressScreen> createState() => _MoodStressScreenState();
}

class _MoodStressScreenState extends State<MoodStressScreen>
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
              AppTheme.primaryPink.withOpacity(0.1),
              AppTheme.accentTeal.withOpacity(0.1),
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
                                   _buildMoodOverview(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildStressAnalysis(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildMoodHistory(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildMoodInsights(cycleProvider),
                                   const SizedBox(height: 16),
                                   _buildStressManagementTips(),
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
            AppTheme.primaryPink.withOpacity(0.3),
            AppTheme.secondaryPurple.withOpacity(0.3),
            AppTheme.accentTeal.withOpacity(0.2),
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
            color: AppTheme.primaryPink.withOpacity(0.2),
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
                                     'mood_stress.title'.tr(),
                   style: TextStyle(
                     color: Colors.white,
                     fontSize: 22,
                     fontWeight: FontWeight.w700,
                     letterSpacing: 0.4,
                   ),
                ),
                Text(
                                     'mood_stress.subtitle'.tr(),
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
              color: AppTheme.primaryPink.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.sentiment_satisfied,
              color: AppTheme.primaryPink,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

     Widget _buildMoodOverview(CycleProvider cycleProvider) {
     final recentEntries = cycleProvider.cycleEntries.take(10).toList();
     final moodEntries = recentEntries.where((e) => e.mood != null).toList();
     
     return Container(
       padding: const EdgeInsets.all(20),
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.1),
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
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.sentiment_satisfied,
                  color: AppTheme.primaryPink,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mood_stress.mood.overview.title'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'mood_stress.mood.overview.subtitle'.tr(),
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
          
          if (moodEntries.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMoodStat(
                    'mood_stress.mood.overview.most_common'.tr(),
                    _getMostCommonMood(moodEntries),
                    Icons.trending_up,
                    AppTheme.primaryPink,
                  ),
                ),
                Expanded(
                  child: _buildMoodStat(
                    'mood_stress.mood.overview.recent'.tr(),
                    moodEntries.first.mood!,
                    Icons.access_time,
                    AppTheme.accentTeal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMoodChart(moodEntries),
          ] else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.sentiment_neutral,
                    color: Colors.white.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'mood_stress.mood.overview.no_data.title'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'mood_stress.mood.overview.no_data.subtitle'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
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

  Widget _buildMoodStat(String label, String value, IconData icon, Color color) {
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart(List<CycleEntry> moodEntries) {
    final moodCounts = <String, int>{};
    for (final entry in moodEntries.take(7)) {
      moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'mood_stress.mood.overview.distribution'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ...moodCounts.entries.map((entry) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getMoodColor(entry.key),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    color: Colors.white, // More solid white for better visibility
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ).toList(),
      ],
    );
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joyful':
      case 'excited':
        return AppTheme.successGreen;
      case 'calm':
      case 'peaceful':
      case 'relaxed':
        return AppTheme.accentTeal;
      case 'sad':
      case 'down':
      case 'depressed':
        return AppTheme.errorRed;
      case 'anxious':
      case 'worried':
      case 'stressed':
        return AppTheme.warningOrange;
      default:
        return AppTheme.primaryPink;
    }
  }

  Widget _buildStressAnalysis(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    final stressEntries = recentEntries.where((e) => e.stressLevel != null).toList();
    
    if (stressEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.accentTeal.withOpacity(0.15),
              AppTheme.successGreen.withOpacity(0.1),
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
                Icons.psychology,
                color: AppTheme.accentTeal,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'mood_stress.stress.analysis.no_data.title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'mood_stress.stress.analysis.no_data.subtitle'.tr(),
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

    final avgStress = stressEntries.map((e) => e.stressLevel!).reduce((a, b) => a + b) / stressEntries.length;
    final stressTrend = _getStressTrend(stressEntries);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.15),
            AppTheme.successGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentTeal.withOpacity(0.3),
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
                  color: AppTheme.accentTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.psychology,
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
                      'mood_stress.stress.analysis.title'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'mood_stress.stress.analysis.subtitle'.tr(),
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
                child: _buildStressStat(
                  'mood_stress.stress.analysis.average'.tr(),
                  '${avgStress.toStringAsFixed(1)}/10',
                  Icons.analytics,
                  AppTheme.accentTeal,
                ),
              ),
              Expanded(
                child: _buildStressStat(
                  'mood_stress.stress.analysis.trend'.tr(),
                  stressTrend,
                  Icons.trending_up,
                  _getStressTrendColor(stressTrend),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          _buildStressRecommendations(avgStress),
        ],
      ),
    );
  }

  Widget _buildStressStat(String label, String value, IconData icon, Color color) {
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStressTrend(List<CycleEntry> entries) {
    if (entries.length < 2) return 'N/A';
    
    final recent = entries.take(3).map((e) => e.stressLevel!).toList();
    final older = entries.skip(3).take(3).map((e) => e.stressLevel!).toList();
    
    if (recent.isEmpty || older.isEmpty) return 'N/A';
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    if (recentAvg < olderAvg - 1) return 'mood_stress.stress.trends.improving'.tr();
    if (recentAvg > olderAvg + 1) return 'mood_stress.stress.trends.increasing'.tr();
    return 'mood_stress.stress.trends.stable'.tr();
  }

  Color _getStressTrendColor(String trend) {
    switch (trend) {
      case String s when s == 'mood_stress.stress.trends.improving'.tr():
        return AppTheme.successGreen;
      case String s when s == 'mood_stress.stress.trends.increasing'.tr():
        return AppTheme.errorRed;
      case String s when s == 'mood_stress.stress.trends.stable'.tr():
        return AppTheme.accentTeal;
      default:
        return AppTheme.primaryPink;
    }
  }

  Widget _buildStressRecommendations(double avgStress) {
    String recommendation;
    Color color;
    
    if (avgStress <= 3) {
      recommendation = 'mood_stress.stress.recommendations.low'.tr();
      color = AppTheme.successGreen;
    } else if (avgStress <= 6) {
      recommendation = 'mood_stress.stress.recommendations.medium'.tr();
      color = AppTheme.warningOrange;
    } else {
      recommendation = 'mood_stress.stress.recommendations.high'.tr();
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

  Widget _buildMoodHistory(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries
        .where((e) => e.mood != null)
        .take(10)
        .toList();
    
    if (recentEntries.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryPurple.withOpacity(0.15),
            AppTheme.primaryPink.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.secondaryPurple.withOpacity(0.3),
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
                  color: AppTheme.secondaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.history,
                  color: AppTheme.secondaryPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'mood_stress.mood.history.title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...recentEntries.map((entry) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.mood!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getMoodColor(entry.mood!).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getMoodColor(entry.mood!).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getMoodIcon(entry.mood!),
                        color: _getMoodColor(entry.mood!),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.mood!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case String s when s == 'mood_stress.mood.types.happy'.tr():
      case String s when s == 'mood_stress.mood.types.joyful'.tr():
      case String s when s == 'mood_stress.mood.types.excited'.tr():
        return Icons.sentiment_very_satisfied;
      case String s when s == 'mood_stress.mood.types.calm'.tr():
      case String s when s == 'mood_stress.mood.types.peaceful'.tr():
      case String s when s == 'mood_stress.mood.types.relaxed'.tr():
        return Icons.sentiment_satisfied;
      case String s when s == 'mood_stress.mood.types.sad'.tr():
      case String s when s == 'mood_stress.mood.types.down'.tr():
      case String s when s == 'mood_stress.mood.types.depressed'.tr():
        return Icons.sentiment_very_dissatisfied;
      case String s when s == 'mood_stress.mood.types.anxious'.tr():
      case String s when s == 'mood_stress.mood.types.worried'.tr():
      case String s when s == 'mood_stress.mood.types.stressed'.tr():
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Widget _buildMoodInsights(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(20).toList();
    final moodEntries = recentEntries.where((e) => e.mood != null).toList();
    
    if (moodEntries.isEmpty) return const SizedBox.shrink();
    
    final insights = _generateMoodInsights(moodEntries);
    
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
                  Icons.insights,
                  color: AppTheme.successGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'mood_stress.mood.insights.title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ...insights.map((insight) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
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

  List<String> _generateMoodInsights(List<CycleEntry> entries) {
    final insights = <String>[];
    final moodCounts = <String, int>{};
    
    for (final entry in entries) {
      moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
    }
    
    final totalEntries = entries.length;
    final mostCommonMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final moodPercentage = (mostCommonMood.value / totalEntries * 100).round();
    
    insights.add('Your most common mood is ${mostCommonMood.key} (${moodPercentage}%)');
    
    if (moodCounts.length >= 3) {
      insights.add('You experienced ${moodCounts.length} different moods');
    }
    
    if (moodCounts.containsKey('happy') || moodCounts.containsKey('joyful')) {
      insights.add('Great! You\'re experiencing positive emotions');
    }
    
    if (moodCounts.containsKey('stressed') || moodCounts.containsKey('anxious')) {
      insights.add('Consider stress management techniques');
    }
    
    return insights;
  }

  Widget _buildStressManagementTips() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningOrange.withOpacity(0.15),
            AppTheme.primaryPink.withOpacity(0.1),
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
                  Icons.self_improvement,
                  color: AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'mood_stress.stress.tips.title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          ..._getStressManagementTips().map((tip) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange,
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

  List<String> _getStressManagementTips() {
    final tips = <String>[];
    for (var i = 0; i < 8; i++) {
      tips.add('mood_stress.stress.tips.list.$i'.tr());
    }
    return tips;
  }

  String _getMostCommonMood(List<CycleEntry> entries) {
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
    }
    final mostCommon = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return mostCommon.key;
  }
}
