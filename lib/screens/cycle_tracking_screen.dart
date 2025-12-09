import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'package:ovumate/models/cycle_entry.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/responsive_layout.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:ovumate/widgets/cycle_statistics_widget.dart';
import 'package:ovumate/screens/add_entry_screen.dart';
import 'package:ovumate/screens/lifestyle_screen.dart';
import 'package:ovumate/screens/partner_share_screen.dart';
import 'package:ovumate/utils/whatsapp_share.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ovumate/screens/mood_stress_screen.dart';
import 'package:ovumate/screens/sleep_water_screen.dart';
import 'package:ovumate/screens/notifications_screen.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';

class CycleTrackingScreen extends StatefulWidget {
  const CycleTrackingScreen({super.key});

  @override
  State<CycleTrackingScreen> createState() => _CycleTrackingScreenState();
}

class _CycleTrackingScreenState extends State<CycleTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentTabIndex = 0; // 0: Overview, 1: Calendar, 2: Statistics, 3: Lifestyle

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Add beautiful entrance animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
    
    // Initialize data after the first frame to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
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

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    // Initialize cycle provider (with or without user)
    if (authProvider.currentUser != null) {
      await cycleProvider.initialize(authProvider.currentUser!.id);
    } else {
      // For testing, initialize without user
      await cycleProvider.initialize();
    }
    
    // Load notifications
    await notificationProvider.loadPendingNotifications();
    
    // Schedule cycle-based notifications
    await _scheduleCycleNotifications(cycleProvider, notificationProvider);
    
    // Check for new articles
    await notificationProvider.checkAndNotifyNewArticles();
    
    // Show welcome message on first visit
    _checkAndShowWelcomeMessage();
  }

  // Schedule cycle-based notifications
  Future<void> _scheduleCycleNotifications(
    CycleProvider cycleProvider,
    NotificationProvider notificationProvider,
  ) async {
    try {
      // Schedule next cycle date notification
      if (cycleProvider.nextPeriodStart != null) {
        await notificationProvider.scheduleNextCycleDateNotification(
          nextCycleDate: cycleProvider.nextPeriodStart!,
        );
      }
      
      // Schedule safe period notification
      final safePeriodStart = cycleProvider.safePeriodStart;
      if (safePeriodStart != null) {
        await notificationProvider.scheduleSafePeriodNotification(
          safePeriodStart: safePeriodStart,
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule cycle notifications: $e');
    }
  }

  Future<void> _checkAndShowWelcomeMessage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasVisitedCyclePage = prefs.getBool('has_visited_cycle_page') ?? false;
      
      // Only show if it's the first time
      if (!hasVisitedCyclePage) {
        // Mark as visited
        await prefs.setBool('has_visited_cycle_page', true);
        
        // Wait a bit for the screen to load
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final user = authProvider.currentUser;
          
          final welcomeMessage = user?.firstName != null
              ? 'Welcome, ${user!.firstName}! 👋 Start tracking your cycle to get personalized insights'
              : 'Welcome to Cycle Tracking! 👋 Start tracking your cycle to get personalized insights';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      welcomeMessage,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryPink,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error showing welcome message: $e');
    }
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
              AppTheme.secondaryPurple.withOpacity(0.4),
              AppTheme.primaryPink.withOpacity(0.1),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Custom App Bar
                _buildCustomAppBar(),
                
                // Tab Navigation
                _buildTabNavigation(),
                
                // Content based on selected tab
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundDark,
            AppTheme.secondaryPurple.withOpacity(0.5),
            AppTheme.primaryPink.withOpacity(0.2),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
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
          // Top row with logo and controls
          Row(
            children: [
              // Professional logo section
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryPink.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: AppTheme.primaryPink,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'app.title'.tr(),
                    style: ResponsiveTheme.getResponsiveTitleStyle(
                      context,
                      fontWeight: FontWeight.w800,
                    ).copyWith(
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Notification icon with real data
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  // Load notifications when widget builds
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notificationProvider.loadPendingNotifications();
                  });
                  
                  final notificationCount = notificationProvider.notificationCount;
                  final hasNotifications = notificationCount > 0;
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            hasNotifications 
                                ? Icons.notifications 
                                : Icons.notifications_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          // Notification badge - show only when there are notifications
                          if (hasNotifications)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                padding: notificationCount > 9 
                                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                                    : const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRed,
                                  shape: notificationCount > 9 
                                      ? BoxShape.rectangle 
                                      : BoxShape.circle,
                                  borderRadius: notificationCount > 9 
                                      ? BorderRadius.circular(8) 
                                      : null,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  notificationCount > 99 ? '99+' : '$notificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 12),
              
              // Partner sharing icon
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PartnerShareScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Title section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryPink.withOpacity(0.2),
                      AppTheme.accentTeal.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryPink.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.calendar_today,
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
                      'cycle_tracking.title'.tr(),
                      style: ResponsiveTheme.getResponsiveTitleStyle(
                        context,
                        fontWeight: FontWeight.w800,
                      ).copyWith(
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'cycle_tracking.description'.tr(),
                      style: ResponsiveTheme.getResponsiveBodyStyle(
                        context,
                        fontWeight: FontWeight.w500,
                      ).copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'cycle_tracking.tabs.overview'.tr(),
                    Icons.dashboard,
                    0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    'cycle_tracking.tabs.calendar'.tr(),
                    Icons.calendar_month,
                    1,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    'cycle_tracking.tabs.statistics'.tr(),
                    Icons.analytics,
                    2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    'cycle_tracking.tabs.lifestyle'.tr(),
                    Icons.favorite,
                    3,
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(
                    'cycle_tracking.tabs.overview'.tr(),
                    Icons.dashboard,
                    0,
                  ),
                  const SizedBox(width: 12),
                  _buildTabButton(
                    'cycle_tracking.tabs.calendar'.tr(),
                    Icons.calendar_month,
                    1,
                  ),
                  const SizedBox(width: 12),
                  _buildTabButton(
                    'cycle_tracking.tabs.statistics'.tr(),
                    Icons.analytics,
                    2,
                  ),
                  const SizedBox(width: 12),
                  _buildTabButton(
                    'cycle_tracking.tabs.lifestyle'.tr(),
                    Icons.favorite,
                    3,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index) {
    final isSelected = _currentTabIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    AppTheme.primaryPink.withOpacity(0.3),
                    AppTheme.accentTeal.withOpacity(0.3),
                  ]
                : [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryPink.withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryPink.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryPink : Colors.white.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: ResponsiveTheme.getResponsiveCaptionStyle(
                context,
                fontWeight: FontWeight.w600,
              ).copyWith(
                color: isSelected ? AppTheme.primaryPink : Colors.white.withOpacity(0.7),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildCalendarTab();
      case 2:
        return _buildStatisticsTab();
      case 3:
        return _buildLifestyleTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _buildOverviewTab() {
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Current Cycle Status
                _buildCurrentCycleStatus(cycleProvider),
                const SizedBox(height: 20),
                
                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 20),
                
                // Next Period & Ovulation
                _buildNextEvents(cycleProvider),
                const SizedBox(height: 20),
                
                // Recent Symptoms
                _buildRecentSymptoms(cycleProvider),
                const SizedBox(height: 20),
                
                // Cycle Insights
                _buildCycleInsights(cycleProvider),
                const SizedBox(height: 20),
                
                // WhatsApp Sharing
                _buildWhatsAppSharing(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Fertility Window Prediction
                _buildFertilityWindow(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Symptom Trends
                _buildSymptomTrends(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Cycle Health Score
                _buildCycleHealthScore(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Medication & Supplements Tracker
                _buildMedicationTracker(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Mood & Stress Tracker
                _buildMoodStressTracker(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Sleep & Water Analytics
                _buildSleepWaterAnalytics(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Period Flow Intensity Tracker
                _buildPeriodFlowTracker(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Cycle Irregularity Alerts
                _buildCycleIrregularityAlerts(cycleProvider),
                
                const SizedBox(height: 20),
                
                // Wellness Tips & Recommendations
                _buildWellnessTips(cycleProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentCycleStatus(CycleProvider cycleProvider) {
    final currentPhase = cycleProvider.currentPhase;
    final daysUntilNextPeriod = cycleProvider.nextPeriodStart
        ?.difference(DateTime.now()).inDays;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPink.withOpacity(0.2),
            AppTheme.accentTeal.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTheme.accentTeal.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                  Icons.calendar_today,
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
                      'cycle_tracking.current_status'.tr(),
                      style: ResponsiveTheme.getResponsiveTitleStyle(
                        context,
                        fontWeight: FontWeight.w700,
                      ).copyWith(
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                    Text(
                      currentPhase.phaseDisplayName,
                      style: ResponsiveTheme.getResponsiveBodyStyle(
                        context,
                        fontWeight: FontWeight.w600,
                      ).copyWith(
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (daysUntilNextPeriod != null && daysUntilNextPeriod > 0) ...[
            Row(
              children: [
                Text(
                  '${daysUntilNextPeriod}',
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w800,
                  ).copyWith(
                    color: AppTheme.textPrimaryDark,
                    fontSize: ResponsiveLayout.isMobile(context) ? 36 : 48,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'cycle_tracking.days_until_label'.tr(),
                        style: ResponsiveTheme.getResponsiveBodyStyle(
                          context,
                          fontWeight: FontWeight.w500,
                        ).copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'cycle_tracking.next_period_label'.tr(),
                        style: ResponsiveTheme.getResponsiveTitleStyle(
                          context,
                          fontWeight: FontWeight.w700,
                        ).copyWith(
                          color: AppTheme.textPrimaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Flexible(
                  child: Text(
                    'cycle_tracking.period'.tr(),
                    style: ResponsiveTheme.getResponsiveTitleStyle(
                      context,
                      fontWeight: FontWeight.w800,
                    ).copyWith(
                      color: AppTheme.textPrimaryDark,
                      fontSize: ResponsiveLayout.isMobile(context) ? 24 : 32,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'cycle_tracking.status.active'.tr(),
                    style: ResponsiveTheme.getResponsiveTitleStyle(
                      context,
                      fontWeight: FontWeight.w700,
                    ).copyWith(
                      color: AppTheme.errorRed,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard.withOpacity(0.9),
            AppTheme.surfaceCard.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flash_on,
                  color: AppTheme.primaryPink,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'cycle_tracking.quick_actions.title'.tr(),
                style: ResponsiveTheme.getResponsiveCaptionStyle(
                  context,
                  fontWeight: FontWeight.w700,
                ).copyWith(
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Improved grid layout for better alignment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildActionButton(
                  'cycle_tracking.quick_actions.log_period'.tr(),
                  Icons.water_drop_rounded,
                  AppTheme.primaryPink,
                  () => _navigateToAddEntry(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'cycle_tracking.quick_actions.log_symptoms'.tr(),
                  Icons.favorite_rounded,
                  AppTheme.errorRed,
                  () => _navigateToAddEntry(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'cycle_tracking.quick_actions.lifestyle'.tr(),
                  Icons.spa_rounded,
                  AppTheme.accentTeal,
                  () => _navigateToLifestyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextEvents(CycleProvider cycleProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cycle_tracking.upcoming_events.title'.tr(),
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Clean, simple layout for upcoming events
          if (cycleProvider.nextPeriodStart != null) ...[
            _buildEventItem(
              'cycle_tracking.next_period'.tr(),
              cycleProvider.nextPeriodStart!,
              Icons.event,
              AppTheme.errorRed,
            ),
            const SizedBox(height: 12),
          ],
          
          if (cycleProvider.nextOvulationDate != null) ...[
            _buildEventItem(
              'cycle_tracking.upcoming_events.next_ovulation'.tr(),
              cycleProvider.nextOvulationDate!,
              Icons.egg,
              AppTheme.warningOrange,
            ),
            const SizedBox(height: 12),
          ],
          
          if (cycleProvider.fertileWindow.isNotEmpty) ...[
            _buildEventItem(
              'cycle_tracking.upcoming_events.fertile_window'.tr(),
              cycleProvider.fertileWindow.first,
              Icons.favorite,
              AppTheme.successGreen,
              endDate: cycleProvider.fertileWindow.last,
            ),
          ],
          
          if (cycleProvider.nextPeriodStart == null && 
              cycleProvider.nextOvulationDate == null && 
              cycleProvider.fertileWindow.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.white.withOpacity(0.5),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No upcoming events',
                      style: ResponsiveTheme.getResponsiveBodyStyle(
                        context,
                      ).copyWith(
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventItem(String label, DateTime date, IconData icon, Color color, {DateTime? endDate}) {
    final daysUntil = date.difference(DateTime.now()).inDays;
    final dateText = endDate != null 
        ? '${date.day}/${date.month} - ${endDate.day}/${endDate.month}'
        : '${date.day}/${date.month}/${date.year}';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ResponsiveTheme.getResponsiveBodyStyle(
                  context,
                  fontWeight: FontWeight.w500,
                ).copyWith(
                  color: Colors.black87,
                ),
              ),
              Text(
                dateText,
                style: ResponsiveTheme.getResponsiveBodyStyle(
                  context,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        if (daysUntil > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${daysUntil}d',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRecentSymptoms(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(3).toList();
    final allSymptoms = <String>{};
    
    for (final entry in recentEntries) {
      allSymptoms.addAll(entry.symptoms);
    }
    
    if (allSymptoms.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryPurple.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondaryPurple.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryPurple.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppTheme.secondaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.symptoms.recent'.tr(),
                style: ResponsiveTheme.getResponsiveTitleStyle(
                  context,
                  fontWeight: FontWeight.w700,
                ).copyWith(
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSymptoms.take(6).map((symptom) => 
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.secondaryPurple.withOpacity(0.3),
                      AppTheme.primaryPink.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.secondaryPurple.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryPurple.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  _translateSymptom(symptom),
                  style: ResponsiveTheme.getResponsiveCaptionStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleInsights(CycleProvider cycleProvider) {
    // Get actual calculated values from user data
    final avgCycleLength = cycleProvider.averageCycleLength;
    final avgPeriodLength = cycleProvider.averagePeriodLength;
    final cyclesTracked = cycleProvider.cyclesTracked;
    
    // Check if we have enough data for accurate calculations
    final periodEntries = cycleProvider.periodEntries;
    final hasEnoughData = periodEntries.length >= 2;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.1),
            AppTheme.accentTeal.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentTeal.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cycle_tracking.insights.title'.tr(),
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.textPrimaryDark 
                  : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  context,
                  hasEnoughData 
                      ? '$avgCycleLength' 
                      : '${Constants.defaultCycleLength}*',
                  'cycle_tracking.insights.overview.avg_cycle',
                  'cycle_tracking.insights.overview.days',
                  showNote: !hasEnoughData,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInsightItem(
                  context,
                  periodEntries.isNotEmpty && avgPeriodLength > 0
                      ? '$avgPeriodLength'
                      : '${Constants.defaultPeriodLength}*',
                  'cycle_tracking.insights.overview.avg_period',
                  'cycle_tracking.insights.overview.days',
                  showNote: periodEntries.isEmpty || avgPeriodLength == 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInsightItem(
                  context,
                  '$cyclesTracked',
                  'cycle_tracking.insights.overview.cycles_tracked',
                  '',
                ),
              ),
            ],
          ),
          
          // Show note if using default values
          if (!hasEnoughData || periodEntries.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '* ${'cycle_tracking.insights.need_more_data'.tr()}',
              style: ResponsiveTheme.getResponsiveCaptionStyle(
                context,
              ).copyWith(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppTheme.textSecondaryDark 
                    : AppTheme.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, String value, String labelKey, String unitKey, {bool showNote = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get translated text
    String labelText;
    String unitText = '';
    
    try {
      labelText = labelKey.tr();
      if (unitKey.isNotEmpty) {
        unitText = unitKey.tr();
      }
    } catch (e) {
      debugPrint('❌ Translation error for key: $labelKey => $e');
      labelText = labelKey; // Fallback to key if translation fails
      if (unitKey.isNotEmpty) {
        unitText = unitKey;
      }
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: ResponsiveTheme.getResponsiveTitleStyle(
            context,
            fontWeight: FontWeight.w700,
          ).copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          labelText,
          style: ResponsiveTheme.getResponsiveCaptionStyle(
            context,
            fontWeight: FontWeight.w500,
          ).copyWith(
            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (unitText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            unitText,
            style: ResponsiveTheme.getResponsiveCaptionStyle(
              context,
              fontWeight: FontWeight.w400,
            ).copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildWhatsAppSharing(CycleProvider cycleProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Share',
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: AppTheme.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildShareButtonWithChart(
                  'cycle_tracking.quick_share.cycle_summary'.tr(),
                  Icons.calendar_today,
                  AppTheme.primaryPink,
                  () => _shareCycleSummary(cycleProvider),
                  cycleProvider,
                  'cycle_summary',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildShareButtonWithChart(
                  'cycle_tracking.quick_share.ovulation'.tr(),
                  Icons.egg,
                  AppTheme.warningOrange,
                  () => _shareOvulationInfo(cycleProvider),
                  cycleProvider,
                  'ovulation',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButtonWithChart(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
    CycleProvider cycleProvider,
    String chartType,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            SizedBox(
              height: 80,
              width: 80,
              child: _buildPieChart(cycleProvider, chartType, color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildColorLegend(chartType, color),
          ],
        ),
      ),
    );
  }

  Widget _buildColorLegend(String chartType, Color baseColor) {
    if (chartType == 'cycle_summary') {
      return Column(
        children: [
          _buildPieChartLegendItem(Colors.red.withOpacity(0.8), 'Period', 8),
          const SizedBox(height: 4),
          _buildPieChartLegendItem(baseColor.withOpacity(0.6), 'Follicular', 8),
          const SizedBox(height: 4),
          _buildPieChartLegendItem(baseColor, 'Ovulation', 8),
          const SizedBox(height: 4),
          _buildPieChartLegendItem(baseColor.withOpacity(0.4), 'Luteal', 8),
        ],
      );
    } else if (chartType == 'ovulation') {
      return Column(
        children: [
          _buildPieChartLegendItem(baseColor, 'Fertile', 8),
          const SizedBox(height: 4),
          _buildPieChartLegendItem(baseColor.withOpacity(0.3), 'Non-Fertile', 8),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPieChartLegendItem(Color color, String label, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(CycleProvider cycleProvider, String chartType, Color baseColor) {
    List<PieChartSectionData> sections = [];
    
    if (chartType == 'cycle_summary') {
      // Cycle Summary Pie Chart: Show cycle phases distribution
      final avgCycleLength = cycleProvider.averageCycleLength;
      final avgPeriodLength = cycleProvider.averagePeriodLength;
      
      if (avgCycleLength > 0) {
        final periodPercent = (avgPeriodLength / avgCycleLength * 100).clamp(0.0, 100.0);
        final follicularPercent = ((avgCycleLength - avgPeriodLength) * 0.3 / avgCycleLength * 100).clamp(0.0, 100.0);
        final ovulationPercent = ((avgCycleLength - avgPeriodLength) * 0.1 / avgCycleLength * 100).clamp(0.0, 100.0);
        final lutealPercent = 100 - periodPercent - follicularPercent - ovulationPercent;
        
        sections = [
          PieChartSectionData(
            value: periodPercent,
            color: Colors.red.withOpacity(0.8),
            title: '',
            radius: 30,
          ),
          PieChartSectionData(
            value: follicularPercent,
            color: baseColor.withOpacity(0.6),
            title: '',
            radius: 30,
          ),
          PieChartSectionData(
            value: ovulationPercent,
            color: baseColor,
            title: '',
            radius: 30,
          ),
          PieChartSectionData(
            value: lutealPercent,
            color: baseColor.withOpacity(0.4),
            title: '',
            radius: 30,
          ),
        ];
      } else {
        // Default empty chart
        sections = [
          PieChartSectionData(
            value: 100,
            color: Colors.grey.withOpacity(0.3),
            title: '',
            radius: 30,
          ),
        ];
      }
    } else if (chartType == 'ovulation') {
      // Ovulation Pie Chart: Show fertile vs non-fertile days
      final avgCycleLength = cycleProvider.averageCycleLength;
      
      if (avgCycleLength > 0) {
        // Fertile window is typically 6 days (5 days before + ovulation day)
        final fertileDays = 6.0;
        final fertilePercent = (fertileDays / avgCycleLength * 100).clamp(0.0, 100.0);
        final nonFertilePercent = 100 - fertilePercent;
        
        sections = [
          PieChartSectionData(
            value: fertilePercent,
            color: baseColor,
            title: '',
            radius: 30,
          ),
          PieChartSectionData(
            value: nonFertilePercent,
            color: baseColor.withOpacity(0.3),
            title: '',
            radius: 30,
          ),
        ];
      } else {
        // Default empty chart
        sections = [
          PieChartSectionData(
            value: 100,
            color: Colors.grey.withOpacity(0.3),
            title: '',
            radius: 30,
          ),
        ];
      }
    }
    
    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 20,
        startDegreeOffset: -90,
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Monthly Calendar Widget
                _buildMonthlyCalendar(cycleProvider),
                const SizedBox(height: 20),
                
                // Monthly Overview
                _buildMonthlyOverview(cycleProvider),
                const SizedBox(height: 20),
                
                // Recent Entries Calendar
                _buildRecentEntriesCalendar(cycleProvider),
                const SizedBox(height: 20),
                
                // Upcoming Events
                _buildUpcomingEvents(cycleProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            const CycleStatisticsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildLifestyleTab() {
    return Consumer<CycleProvider>(
      builder: (context, cycleProvider, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Lifestyle Summary
                _buildLifestyleSummary(cycleProvider),
                const SizedBox(height: 20),
                
                // Recent Lifestyle Entries
                _buildRecentLifestyleEntries(cycleProvider),
                const SizedBox(height: 20),
                
                // Wellness Insights
                _buildWellnessInsights(cycleProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToAddEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEntryScreen(),
      ),
    );
  }

  void _navigateToLifestyle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LifestyleScreen(),
      ),
    );
  }

  void _shareCycleSummary(CycleProvider cycleProvider) async {
    if (cycleProvider.nextPeriodStart != null) {
      final success = await WhatsAppShare.shareCycleSummary(
        nextPeriodDate: cycleProvider.nextPeriodStart!,
        nextOvulationDate: cycleProvider.nextOvulationDate,
        cycleLength: cycleProvider.averageCycleLength,
        periodLength: cycleProvider.averagePeriodLength,
      );
      
      if (!success && mounted) {
        _showMessage('Could not open WhatsApp. Please make sure WhatsApp is installed.');
      }
    } else {
      _showMessage('No cycle data available to share yet.');
    }
  }

  void _shareOvulationInfo(CycleProvider cycleProvider) async {
    if (cycleProvider.nextOvulationDate != null) {
      final ovulationDate = cycleProvider.nextOvulationDate!;
      final fertileWindowStart = ovulationDate.subtract(const Duration(days: 3));
      final fertileWindowEnd = ovulationDate.add(const Duration(days: 1));
      
      final success = await WhatsAppShare.shareOvulationReminder(
        ovulationDate: ovulationDate,
        fertileWindowStart: fertileWindowStart,
        fertileWindowEnd: fertileWindowEnd,
      );
      
      if (!success && mounted) {
        _showMessage('Could not open WhatsApp. Please make sure WhatsApp is installed.');
      }
    } else {
      _showMessage('No ovulation data available to share yet.');
    }
  }

  Widget _buildDataPersistenceStatus(CycleProvider cycleProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successGreen.withOpacity(0.1),
            AppTheme.successGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.successGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.save,
                  color: AppTheme.successGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Data Persistence Status',
                style: ResponsiveTheme.getResponsiveTitleStyle(
                  context,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: AppTheme.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildPersistenceItem(
                  'cycle_tracking.calendar.total_entries'.tr(),
                  '${cycleProvider.cycleEntries.length}',
                  Icons.data_usage,
                  AppTheme.successGreen,
                ),
              ),
              Expanded(
                child: _buildPersistenceItem(
                  'Database Status',
                  cycleProvider.isInitialized ? 'Connected' : 'Disconnected',
                  Icons.storage,
                  cycleProvider.isInitialized ? AppTheme.successGreen : AppTheme.errorRed,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildPersistenceItem(
                  'Authentication',
                  'Guest Mode',
                  Icons.person,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildPersistenceItem(
                  'Data Storage',
                  'Local + Cloud',
                  Icons.save,
                  AppTheme.successGreen,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data is automatically saved to:',
                  style: ResponsiveTheme.getResponsiveBodyStyle(
                    context,
                    fontWeight: FontWeight.w500,
                  ).copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPersistenceFeature('📱 Local Device Storage'),
                _buildPersistenceFeature('☁️ Cloud Database (Supabase)'),
                _buildPersistenceFeature('🔄 Real-time Sync'),
                _buildPersistenceFeature('💾 Automatic Backup'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Running in guest mode. Data will be saved locally for testing purposes.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersistenceItem(String label, String value, IconData icon, Color color) {
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
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: ResponsiveTheme.getResponsiveCaptionStyle(
            context,
            fontWeight: FontWeight.w500,
          ).copyWith(
            color: AppTheme.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPersistenceFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.successGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: ResponsiveTheme.getResponsiveBodyStyle(
              context,
              fontWeight: FontWeight.w500,
            ).copyWith(
              color: AppTheme.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryPink,
      ),
    );
  }

  // Quick Share Methods
  Widget _buildQuickShareSection(CycleProvider cycleProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.2),
            AppTheme.secondaryPurple.withOpacity(0.2),
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
                  Icons.share,
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
                      'cycle_tracking.quick_share.title'.tr(),
                      style: ResponsiveTheme.getResponsiveTitleStyle(
                        context,
                        fontWeight: FontWeight.w700,
                      ).copyWith(
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                    Text(
                      'cycle_tracking.quick_share.subtitle'.tr(),
                      style: TextStyle(
                        color: AppTheme.accentTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Quick Share Buttons
          Row(
            children: [
              Expanded(
                child: _buildQuickShareButton(
                  'cycle_tracking.quick_share.share_status'.tr(),
                  Icons.info_outline,
                  AppTheme.primaryPink,
                  () => _showQuickShareOptions(cycleProvider, 'status'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickShareButton(
                  'cycle_tracking.quick_share.share_next_period'.tr(),
                  Icons.calendar_today,
                  AppTheme.warningOrange,
                  () => _showQuickShareOptions(cycleProvider, 'period'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildQuickShareButton(
                  'cycle_tracking.quick_share.share_ovulation'.tr(),
                  Icons.favorite,
                  AppTheme.successGreen,
                  () => _showQuickShareOptions(cycleProvider, 'ovulation'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickShareButton(
                  'cycle_tracking.quick_share.share_summary'.tr(),
                  Icons.summarize,
                  AppTheme.secondaryPurple,
                  () => _showQuickShareOptions(cycleProvider, 'summary'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recent Contacts
          _buildRecentContactsSection(),
        ],
      ),
    );
  }

  Widget _buildQuickShareButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'cycle_tracking.quick_share.recent_contacts'.tr(),
          style: ResponsiveTheme.getResponsiveBodyStyle(
            context,
            fontWeight: FontWeight.w600,
          ).copyWith(
            color: AppTheme.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 16),
        
        // Placeholder for recent contacts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: AppTheme.accentTeal,
                size: 20,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'cycle_tracking.quick_share.tap_to_select'.tr(),
                  style: ResponsiveTheme.getResponsiveBodyStyle(
                    context,
                  ).copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQuickShareOptions(CycleProvider cycleProvider, String shareType) async {
    // For web, show manual phone number input
    if (kIsWeb) {
      _showPhoneNumberInputDialog(cycleProvider, shareType);
      return;
    }

    // For mobile, use contact selection
    try {
      // Request contact permission
      final status = await Permission.contacts.request();
      
      if (status.isDenied || status.isPermanentlyDenied) {
        // If permission denied, offer manual input as fallback
        _showPhoneNumberInputDialog(cycleProvider, shareType);
        return;
      }

      // Get contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      
      if (contacts.isEmpty) {
        // If no contacts, offer manual input
        _showPhoneNumberInputDialog(cycleProvider, shareType);
        return;
      }

      // Show contact selection dialog
      _showContactSelectionDialog(contacts, cycleProvider, shareType);
    } catch (e) {
      // On error, fallback to manual input
      _showPhoneNumberInputDialog(cycleProvider, shareType);
    }
  }

  void _showPhoneNumberInputDialog(CycleProvider cycleProvider, String shareType) {
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the phone number to share with (include country code, e.g., +94771234567)'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+94771234567',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              phoneController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phoneNumber = phoneController.text.trim();
              if (phoneNumber.isEmpty) {
                _showMessage('Please enter a phone number');
                return;
              }
              
              phoneController.dispose();
              Navigator.pop(context);
              await _shareWithPhoneNumber(phoneNumber, cycleProvider, shareType);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareWithPhoneNumber(String phoneNumber, CycleProvider cycleProvider, String shareType) async {
    String message = '';
    
    switch (shareType) {
      case 'status':
        message = _buildStatusMessage(cycleProvider);
        break;
      case 'period':
        message = _buildPeriodMessage(cycleProvider);
        break;
      case 'ovulation':
        message = _buildOvulationMessage(cycleProvider);
        break;
      case 'summary':
        message = _buildSummaryMessage(cycleProvider);
        break;
    }

    // Share via WhatsApp
    final success = await WhatsAppShare.shareToContact(
      phoneNumber: phoneNumber,
      message: message,
    );

    if (success) {
      _showMessage('Opening WhatsApp to share...');
    } else {
      _showMessage('Failed to open WhatsApp. Please make sure WhatsApp is installed or try again.');
    }
  }

  void _showContactSelectionDialog(
    List<Contact> contacts,
    CycleProvider cycleProvider,
    String shareType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Contact to Share ${shareType.toUpperCase()}'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6, // Responsive height
          child: Column(
            children: [
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  // TODO: Implement search functionality
                },
              ),
              const SizedBox(height: 16),
              
              // Contacts list
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                                      itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final displayName = contact.displayName?.isNotEmpty == true ? contact.displayName : 'Unknown Contact';
                      final phoneNumbers = contact.phones ?? [];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryPink.withOpacity(0.2),
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: AppTheme.primaryPink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(displayName),
                        subtitle: phoneNumbers.isNotEmpty ? Text(phoneNumbers.first.number) : null,
                        onTap: () {
                          Navigator.pop(context);
                          _shareWithContact(contact, cycleProvider, shareType);
                        },
                      );
                    },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _shareWithContact(Contact contact, CycleProvider cycleProvider, String shareType) async {
    final phoneNumbers = contact.phones ?? [];
    
    if (phoneNumbers.isEmpty) {
      _showMessage('No phone number found for this contact');
      return;
    }

    final phoneNumber = phoneNumbers.first.number;
    if (phoneNumber.isEmpty) {
      _showMessage('Invalid phone number for this contact');
      return;
    }
    
    String message = '';
    
    switch (shareType) {
      case 'status':
        message = _buildStatusMessage(cycleProvider);
        break;
      case 'period':
        message = _buildPeriodMessage(cycleProvider);
        break;
      case 'ovulation':
        message = _buildOvulationMessage(cycleProvider);
        break;
      case 'summary':
        message = _buildSummaryMessage(cycleProvider);
        break;
    }

    // Share via WhatsApp
    final success = await WhatsAppShare.shareToContact(
      phoneNumber: phoneNumber,
      message: message,
    );

    if (success) {
      _showMessage('Shared successfully with ${contact.displayName ?? 'contact'}');
      } else {
      _showMessage('Failed to share. Please make sure WhatsApp is installed.');
    }
  }

  String _buildStatusMessage(CycleProvider cycleProvider) {
    final currentPhase = cycleProvider.currentPhase.phaseDisplayName;
    final daysUntilNextPeriod = cycleProvider.nextPeriodStart
        ?.difference(DateTime.now()).inDays;
    
    return '''🔄 Current Cycle Status: $currentPhase
${daysUntilNextPeriod != null && daysUntilNextPeriod > 0 ? '📅 Next period in $daysUntilNextPeriod days' : '📅 Period information available'}
💪 Tracked with OvuMate App''';
  }

  String _buildPeriodMessage(CycleProvider cycleProvider) {
    final nextPeriodStart = cycleProvider.nextPeriodStart;
    if (nextPeriodStart == null) return 'No period prediction available yet.';
    
    final daysUntil = nextPeriodStart.difference(DateTime.now()).inDays;
    final dateStr = '${nextPeriodStart.day}/${nextPeriodStart.month}/${nextPeriodStart.year}';
    
    return '''🩸 Period Update
📅 Next period expected: $dateStr
⏰ In approximately $daysUntil days
💪 Tracked with OvuMate App''';
  }

  String _buildOvulationMessage(CycleProvider cycleProvider) {
    final nextOvulation = cycleProvider.nextOvulationDate;
    if (nextOvulation == null) return 'No ovulation prediction available yet.';
    
    final daysUntil = nextOvulation.difference(DateTime.now()).inDays;
    final dateStr = '${nextOvulation.day}/${nextOvulation.month}/${nextOvulation.year}';
    
    final fertileWindow = cycleProvider.fertileWindow;
    final fertileStart = fertileWindow.isNotEmpty ? fertileWindow.first : null;
    final fertileEnd = fertileWindow.isNotEmpty ? fertileWindow.last : null;
    
    return '''❤️ Ovulation Update
📅 Next ovulation: $dateStr
⏰ In approximately $daysUntil days
🌱 Fertile window: ${fertileStart != null ? '${fertileStart.day}/${fertileStart.month}' : 'N/A'} - ${fertileEnd != null ? '${fertileEnd.day}/${fertileEnd.month}' : 'N/A'}
💪 Tracked with OvuMate App''';
  }

  String _buildSummaryMessage(CycleProvider cycleProvider) {
    final avgCycleLength = cycleProvider.averageCycleLength ?? 28;
    final avgPeriodLength = cycleProvider.averagePeriodLength ?? 5;
    final cyclesTracked = cycleProvider.cyclesTracked;
    
    return '''📊 Cycle Summary
🔄 Average cycle length: $avgCycleLength days
🩸 Average period length: $avgPeriodLength days
📈 Cycles tracked: $cyclesTracked
💪 Tracked with OvuMate App''';
  }

  // Calendar Tab Helper Methods
  Widget _buildMonthlyCalendar(CycleProvider cycleProvider) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    
    // Get entries for current month
    final monthEntries = cycleProvider.cycleEntries
        .where((entry) => entry.date.month == now.month && entry.date.year == now.year)
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPink.withOpacity(0.1),
            AppTheme.accentTeal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month,
                  color: AppTheme.primaryPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
                        Text(
            '${_getMonthName(now.month)} ${now.year}',
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w700,
            ).copyWith(
              color: AppTheme.textPrimaryDark,
            ),
          ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Weekday headers
          Row(
            children: ['days.sun', 'days.mon', 'days.tue', 'days.wed', 'days.thu', 'days.fri', 'days.sat']
                .map((day) => Expanded(
                      child: Text(
                        day.tr(),
                        textAlign: TextAlign.center,
                        style: ResponsiveTheme.getResponsiveCaptionStyle(
                          context,
                          fontWeight: FontWeight.w600,
                        ).copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          
          // Calendar grid
          ...List.generate((daysInMonth + firstWeekday - 1) ~/ 7 + 1, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
                  final isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;
                  final currentDate = isValidDay ? DateTime(now.year, now.month, dayNumber) : null;
                  
                  // Check if this date has entries
                  final hasEntries = currentDate != null && monthEntries.any((entry) => 
                      entry.date.day == currentDate.day && 
                      entry.date.month == currentDate.month && 
                      entry.date.year == currentDate.year);
                  
                  // Check if this is a period day
                  final isPeriodDay = currentDate != null && monthEntries.any((entry) => 
                      entry.date.day == currentDate.day && 
                      entry.date.month == currentDate.month && 
                      entry.date.year == currentDate.year && 
                      entry.isPeriodDay);
                  
                  // Determine cycle phase for this date
                  CyclePhase? phaseForDate;
                  if (currentDate != null) {
                    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
                    if (cycleProvider.nextPeriodStart != null && cycleProvider.nextOvulationDate != null) {
                      final daysUntilPeriod = cycleProvider.nextPeriodStart!.difference(currentDate).inDays;
                      final daysUntilOvulation = cycleProvider.nextOvulationDate!.difference(currentDate).inDays;
                      
                      if (daysUntilPeriod <= 0) {
                        phaseForDate = CyclePhase.menstrual;
                      } else if (daysUntilOvulation <= 0 && daysUntilOvulation >= -1) {
                        phaseForDate = CyclePhase.ovulation;
                      } else if (daysUntilOvulation > 0) {
                        phaseForDate = CyclePhase.follicular;
                      } else {
                        phaseForDate = CyclePhase.luteal;
                      }
                    }
                  }
                  
                  // Check if this is today
                  final isToday = currentDate != null && 
                      currentDate.day == now.day && 
                      currentDate.month == now.month && 
                      currentDate.year == now.year;
                  
                  // Check if this is in fertile window
                  final isInFertileWindow = currentDate != null && 
                      cycleProvider.fertileWindow.any((date) => 
                          date.day == currentDate.day && 
                          date.month == currentDate.month && 
                          date.year == currentDate.year);
                  
                  return Expanded(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        gradient: isValidDay
                            ? (isPeriodDay
                                ? LinearGradient(
                                    colors: [AppTheme.errorRed.withOpacity(0.8), AppTheme.errorRed.withOpacity(0.6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : isInFertileWindow
                                    ? LinearGradient(
                                        colors: [AppTheme.accentTeal.withOpacity(0.8), AppTheme.accentTeal.withOpacity(0.6)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : hasEntries
                                        ? LinearGradient(
                                            colors: [AppTheme.primaryPink.withOpacity(0.7), AppTheme.secondaryPurple.withOpacity(0.5)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : phaseForDate == CyclePhase.ovulation
                                            ? LinearGradient(
                                                colors: [AppTheme.warningOrange.withOpacity(0.6), AppTheme.warningOrange.withOpacity(0.4)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : phaseForDate == CyclePhase.luteal
                                                ? LinearGradient(
                                                    colors: [AppTheme.successGreen.withOpacity(0.5), AppTheme.successGreen.withOpacity(0.3)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : LinearGradient(
                                                    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ))
                            : LinearGradient(
                                colors: [Colors.transparent, Colors.transparent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isValidDay
                              ? (isToday
                                  ? AppTheme.primaryPink
                                  : isPeriodDay
                                      ? AppTheme.errorRed.withOpacity(0.8)
                                      : isInFertileWindow
                                          ? AppTheme.accentTeal.withOpacity(0.8)
                                          : hasEntries
                                              ? AppTheme.primaryPink.withOpacity(0.6)
                                              : Colors.white.withOpacity(0.2))
                              : Colors.transparent,
                          width: isToday ? 2.5 : 1.5,
                        ),
                        boxShadow: isValidDay && (isPeriodDay || hasEntries || isInFertileWindow)
                            ? [
                                BoxShadow(
                                  color: (isPeriodDay 
                                      ? AppTheme.errorRed 
                                      : isInFertileWindow 
                                          ? AppTheme.accentTeal 
                                          : AppTheme.primaryPink).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              isValidDay ? '$dayNumber' : '',
                              style: ResponsiveTheme.getResponsiveCaptionStyle(
                                context,
                                fontWeight: isValidDay ? FontWeight.w700 : FontWeight.normal,
                              ).copyWith(
                                color: isValidDay
                                    ? (isPeriodDay
                                        ? Colors.white
                                        : isInFertileWindow
                                            ? Colors.white
                                            : hasEntries
                                                ? Colors.white
                                                : isToday
                                                    ? AppTheme.primaryPink
                                                    : AppTheme.textPrimaryDark)
                                    : Colors.transparent,
                                fontSize: isValidDay ? 14 : 12,
                              ),
                            ),
                          ),
                          // Add small indicator for special days
                          if (isValidDay && (isPeriodDay || isInFertileWindow || hasEntries))
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isPeriodDay
                                      ? Colors.white
                                      : isInFertileWindow
                                          ? Colors.white
                                          : AppTheme.primaryPink,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // Enhanced Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'cycle_tracking.calendar.legend'.tr(),
                  style: ResponsiveTheme.getResponsiveCaptionStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem(
                      'cycle_tracking.calendar.period_day'.tr(),
                      LinearGradient(
                        colors: [AppTheme.errorRed.withOpacity(0.8), AppTheme.errorRed.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      Colors.white,
                    ),
                    _buildLegendItem(
                      'cycle_tracking.calendar.fertile_window'.tr(),
                      LinearGradient(
                        colors: [AppTheme.accentTeal.withOpacity(0.8), AppTheme.accentTeal.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      Colors.white,
                    ),
                    _buildLegendItem(
                      'cycle_tracking.calendar.has_entries'.tr(),
                      LinearGradient(
                        colors: [AppTheme.primaryPink.withOpacity(0.7), AppTheme.secondaryPurple.withOpacity(0.5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      Colors.white,
                    ),
                    _buildLegendItem(
                      'cycle_tracking.calendar.ovulation'.tr(),
                      LinearGradient(
                        colors: [AppTheme.warningOrange.withOpacity(0.6), AppTheme.warningOrange.withOpacity(0.4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      Colors.white,
                    ),
                    _buildLegendItem(
                      'cycle_tracking.calendar.luteal_phase'.tr(),
                      LinearGradient(
                        colors: [AppTheme.successGreen.withOpacity(0.5), AppTheme.successGreen.withOpacity(0.3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      Colors.white,
                    ),
                    _buildLegendItem(
                      'cycle_tracking.calendar.today'.tr(),
                      LinearGradient(
                        colors: [Colors.transparent, Colors.transparent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      AppTheme.primaryPink,
                      hasBorder: true,
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

  Widget _buildLegendItem(String label, Gradient gradient, Color textColor, {bool hasBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(6),
            border: hasBorder ? Border.all(color: textColor, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: ResponsiveTheme.getResponsiveCaptionStyle(
            context,
            fontWeight: FontWeight.w500,
          ).copyWith(
            color: AppTheme.textSecondaryDark,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyOverview(CycleProvider cycleProvider) {
    final now = DateTime.now();
    final currentMonthEntries = cycleProvider.cycleEntries
        .where((entry) => entry.date.month == now.month && entry.date.year == now.year)
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${'cycle_tracking.calendar.monthly_overview'.tr()} - ${_getMonthName(now.month)}',
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildCalendarStat(
                  'cycle_tracking.calendar.total_entries'.tr(),
                  '${currentMonthEntries.length}',
                  Icons.calendar_today,
                  AppTheme.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCalendarStat(
                  'cycle_tracking.calendar.period_days'.tr(),
                  '${currentMonthEntries.where((e) => e.isPeriodDay).length}',
                  Icons.favorite,
                  AppTheme.errorRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCalendarStat(
                  'cycle_tracking.calendar.symptom_days'.tr(),
                  '${currentMonthEntries.where((e) => e.symptoms.isNotEmpty).length}',
                  Icons.medical_services,
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntriesCalendar(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(7).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cycle_tracking.calendar.recent_entries'.tr(),
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          if (recentEntries.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.white.withOpacity(0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent entries',
                    style: ResponsiveTheme.getResponsiveBodyStyle(
                      context,
                    ).copyWith(
                      color: AppTheme.textSecondaryDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentEntries.map((entry) => _buildCalendarEntryItem(entry)),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(CycleProvider cycleProvider) {
    final nextPeriod = cycleProvider.nextPeriodStart;
    final nextOvulation = cycleProvider.nextOvulationDate;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cycle_tracking.upcoming_events.title'.tr(),
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          if (nextPeriod != null)
            _buildEventItem(
              'cycle_tracking.next_period'.tr(),
              nextPeriod,
              Icons.favorite,
              AppTheme.errorRed,
            ),
          
          if (nextOvulation != null)
            _buildEventItem(
              'cycle_tracking.calendar.ovulation'.tr(),
              nextOvulation,
              Icons.egg,
              AppTheme.warningOrange,
            ),
          
          if (nextPeriod == null && nextOvulation == null)
            Center(
              child:                 Text(
                  'No upcoming events',
                  style: ResponsiveTheme.getResponsiveBodyStyle(
                    context,
                  ).copyWith(
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarStat(String label, String value, IconData icon, Color color) {
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
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.bold,
            ).copyWith(
              color: color,
            ),
          ),
          Text(
            label,
            style: ResponsiveTheme.getResponsiveCaptionStyle(
              context,
            ).copyWith(
              color: AppTheme.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarEntryItem(CycleEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getEntryColor(entry).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getEntryIcon(entry),
              color: _getEntryColor(entry),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                  style: ResponsiveTheme.getResponsiveBodyStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: Colors.black,
                  ),
                ),
                if (entry.symptoms.isNotEmpty)
                  Text(
                    entry.symptoms.take(3).map((symptom) {
                      // Convert symptom to translation key format (lowercase with underscores)
                      final key = symptom.toLowerCase().replaceAll(' ', '_');
                      // Try to translate, fallback to original if translation key doesn't exist
                      final translationKey = 'cycle_tracking.symptoms_options.$key';
                      return translationKey.tr();
                    }).join(', '),
                    style: ResponsiveTheme.getResponsiveCaptionStyle(
                      context,
                    ).copyWith(
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
          if (entry.isPeriodDay)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'cycle_tracking.calendar.period'.tr(),
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Lifestyle Tab Helper Methods
  Widget _buildLifestyleSummary(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    
    // Calculate averages
    final sleepEntries = recentEntries.where((e) => e.sleepHours != null).toList();
    final waterEntries = recentEntries.where((e) => e.waterIntake != null).toList();
    final stressEntries = recentEntries.where((e) => e.stressLevel != null).toList();
    
    final avgSleep = sleepEntries.isNotEmpty 
        ? sleepEntries.map((e) => e.sleepHours!).reduce((a, b) => a + b) / sleepEntries.length
        : 0.0;
    final avgWater = waterEntries.isNotEmpty
        ? waterEntries.map((e) => e.waterIntake!).reduce((a, b) => a + b) / waterEntries.length
        : 0.0;
    final avgStress = stressEntries.isNotEmpty
        ? stressEntries.map((e) => e.stressLevel!).reduce((a, b) => a + b) / stressEntries.length
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cycle_tracking.lifestyle_summary.title'.tr(),
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildLifestyleStat(
                  'cycle_tracking.sleep_water.avg_sleep'.tr(),
                  '${avgSleep.toStringAsFixed(1)}${'cycle_tracking.units.hours'.tr()}',
                  Icons.bedtime,
                  AppTheme.accentTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLifestyleStat(
                  'cycle_tracking.sleep_water.avg_water'.tr(),
                  '${avgWater.toStringAsFixed(0)}${'cycle_tracking.units.ml'.tr()}',
                  Icons.water_drop,
                  AppTheme.accentTeal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLifestyleStat(
                  'cycle_tracking.lifestyle_summary.avg_stress'.tr(),
                  '${avgStress.toStringAsFixed(1)}/10',
                  Icons.psychology,
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentLifestyleEntries(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cycle_tracking.lifestyle_summary.recent_entries'.tr(),
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          if (recentEntries.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.grey.withOpacity(0.6),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'cycle_tracking.lifestyle_summary.no_entries'.tr(),
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ...recentEntries.map((entry) => _buildLifestyleEntryItem(entry)),
        ],
      ),
    );
  }

  Widget _buildWellnessInsights(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    final moodEntries = recentEntries.where((e) => e.mood != null).toList();
    final activityEntries = recentEntries.where((e) => e.activities.isNotEmpty).toList();
    
    // Get most common mood and activities
    final moodCounts = <String, int>{};
    final activityCounts = <String, int>{};
    
    for (final entry in moodEntries) {
      moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
    }
    
    for (final entry in activityEntries) {
      for (final activity in entry.activities) {
        activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
      }
    }
    
    final mostCommonMood = moodCounts.isNotEmpty ? moodCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b).key : null;
    final mostCommonActivities = activityCounts.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'cycle_tracking.wellness_insights.title'.tr(),
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.w600,
            ).copyWith(
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          if (mostCommonMood != null)
            _buildWellnessInsightItem(
              'cycle_tracking.wellness_insights.most_common_mood'.tr(),
              'cycle_tracking.moods.${mostCommonMood.toLowerCase()}'.tr(),
              Icons.sentiment_satisfied,
              AppTheme.primaryPink,
            ),
          
          if (mostCommonActivities.isNotEmpty)
            _buildWellnessInsightItem(
              'cycle_tracking.wellness_insights.most_common_activity'.tr(),
              'cycle_tracking.activities.${mostCommonActivities.first.key.toLowerCase()}'.tr(),
              Icons.fitness_center,
              AppTheme.accentTeal,
            ),
          
          if (mostCommonMood == null && mostCommonActivities.isEmpty)
            Center(
              child: Text(
                'cycle_tracking.wellness_insights.add_more_entries'.tr(),
                style: ResponsiveTheme.getResponsiveBodyStyle(
                  context,
                ).copyWith(
                  color: Colors.black,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLifestyleStat(String label, String value, IconData icon, Color color) {
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
            style: ResponsiveTheme.getResponsiveTitleStyle(
              context,
              fontWeight: FontWeight.bold,
            ).copyWith(
              color: color,
            ),
          ),
          Text(
            label,
            style: ResponsiveTheme.getResponsiveCaptionStyle(
              context,
            ).copyWith(
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleEntryItem(CycleEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                style: ResponsiveTheme.getResponsiveBodyStyle(
                  context,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              if (entry.mood != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.mood!,
                    style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (entry.sleepHours != null || entry.waterIntake != null || entry.stressLevel != null)
            Row(
              children: [
                if (entry.sleepHours != null)
                  Expanded(
                    child: _buildLifestyleDetail('cycle_tracking.lifestyle_summary.sleep'.tr(), '${entry.sleepHours}${'cycle_tracking.units.hours'.tr()}', Icons.bedtime),
                  ),
                if (entry.waterIntake != null)
                  Expanded(
                    child: _buildLifestyleDetail('cycle_tracking.lifestyle_summary.water'.tr(), '${entry.waterIntake}${'cycle_tracking.units.ml'.tr()}', Icons.water_drop),
                  ),
                if (entry.stressLevel != null)
                  Expanded(
                    child: _buildLifestyleDetail('cycle_tracking.lifestyle_summary.stress'.tr(), '${entry.stressLevel}/10', Icons.psychology),
                  ),
              ],
            ),
          
          if (entry.activities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: entry.activities.map((activity) {
                  final key = activity.toLowerCase();
                  final translationKey = 'cycle_tracking.activities.$key';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      translationKey.tr(),
                      style: TextStyle(
                        color: AppTheme.accentTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
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

  Widget _buildLifestyleDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.textSecondaryDark,
          size: 20,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Text(
                value,
                style: ResponsiveTheme.getResponsiveCaptionStyle(
                  context,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: Colors.black,
                ),
              ),
              Text(
                label,
                style: ResponsiveTheme.getResponsiveCaptionStyle(
                  context,
                ).copyWith(
                  color: Colors.black,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWellnessInsightItem(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ResponsiveTheme.getResponsiveBodyStyle(
                    context,
                    fontWeight: FontWeight.w500,
                  ).copyWith(
                    color: Colors.black,
                  ),
                ),
                Text(
                  value,
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Utility Methods
  String _getMonthName(int month) {
    const monthKeys = [
      'months.january', 'months.february', 'months.march', 'months.april', 
      'months.may', 'months.june', 'months.july', 'months.august', 
      'months.september', 'months.october', 'months.november', 'months.december'
    ];
    return monthKeys[month - 1].tr();
  }

  Color _getEntryColor(CycleEntry entry) {
    if (entry.isPeriodDay) return AppTheme.errorRed;
    if (entry.symptoms.isNotEmpty) return AppTheme.accentTeal;
    return AppTheme.primaryPink;
  }

  IconData _getEntryIcon(CycleEntry entry) {
    if (entry.isPeriodDay) return Icons.favorite;
    if (entry.symptoms.isNotEmpty) return Icons.medical_services;
    return Icons.fitness_center;
  }

  // Professional Period Tracking Features
  Widget _buildFertilityWindow(CycleProvider cycleProvider) {
    final fertileWindow = cycleProvider.fertileWindow;
    final ovulationDate = cycleProvider.nextOvulationDate;
    
    if (fertileWindow.isEmpty || ovulationDate == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.warningOrange.withOpacity(0.1),
              AppTheme.warningOrange.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.egg,
                    color: AppTheme.warningOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'cycle_tracking.fertility_window.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'cycle_tracking.fertility_window.not_enough_data'.tr(),
                style: ResponsiveTheme.getResponsiveBodyStyle(
                  context,
                ).copyWith(
                  color: AppTheme.textSecondaryDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final daysUntilOvulation = ovulationDate.difference(DateTime.now()).inDays;
    final fertileStart = fertileWindow.first;
    final fertileEnd = fertileWindow.last;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningOrange.withOpacity(0.1),
            AppTheme.warningOrange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.egg,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.fertility_window.title'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildFertilityItem(
                  'cycle_tracking.quick_share.ovulation'.tr(),
                  '${ovulationDate.day}/${ovulationDate.month}',
                  daysUntilOvulation > 0 ? '$daysUntilOvulation ${'cycle_tracking.fertility_window.days'.tr()}' : 'cycle_tracking.fertility_window.today'.tr(),
                  Icons.egg,
                  AppTheme.warningOrange,
                ),
              ),
              Expanded(
                child: _buildFertilityItem(
                  'cycle_tracking.fertility_window.fertile_start'.tr(),
                  '${fertileStart.day}/${fertileStart.month}',
                  'cycle_tracking.fertility_window.high_chance'.tr(),
                  Icons.favorite,
                  AppTheme.successGreen,
                ),
              ),
              Expanded(
                child: _buildFertilityItem(
                  'cycle_tracking.fertility_window.fertile_end'.tr(),
                  '${fertileEnd.day}/${fertileEnd.month}',
                  'cycle_tracking.fertility_window.last_chance'.tr(),
                  Icons.favorite,
                  AppTheme.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFertilityItem(String label, String date, String status, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          date,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSymptomTrends(CycleProvider cycleProvider) {
    // Use all entries to calculate symptom trends
    final allEntries = cycleProvider.cycleEntries.toList();
    final symptomCounts = <String, int>{};
    
    // Count all symptoms from all entries
    for (final entry in allEntries) {
      // Check if entry has symptoms
      if (entry.symptoms.isNotEmpty) {
        for (final symptom in entry.symptoms) {
          // Normalize symptom name (trim whitespace, handle case)
          final normalizedSymptom = symptom.trim();
          if (normalizedSymptom.isNotEmpty) {
            symptomCounts[normalizedSymptom] = (symptomCounts[normalizedSymptom] ?? 0) + 1;
          }
        }
      }
    }
    
    // Sort by frequency (most common first), then alphabetically if same frequency
    final sortedSymptoms = symptomCounts.entries.toList()
      ..sort((a, b) {
        final freqCompare = b.value.compareTo(a.value);
        if (freqCompare != 0) return freqCompare;
        return a.key.compareTo(b.key);
      });
    
    // Take top 10 most common symptoms
    final topSymptoms = sortedSymptoms.take(10).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.1),
            AppTheme.accentTeal.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppTheme.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'cycle_tracking.symptom_trends.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w700,
                  ).copyWith(
                    color: AppTheme.secondaryPurple,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (topSymptoms.isNotEmpty)
            ...topSymptoms.map((symptom) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _translateSymptom(symptom.key),
                        style: ResponsiveTheme.getResponsiveBodyStyle(
                          context,
                          fontWeight: FontWeight.w500,
                        ).copyWith(
                          color: AppTheme.secondaryPurple,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentTeal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${symptom.value}x',
                        style: TextStyle(
                          color: AppTheme.accentTeal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No symptoms tracked yet',
                  style: ResponsiveTheme.getResponsiveBodyStyle(
                    context,
                    fontWeight: FontWeight.w500,
                  ).copyWith(
                    color: AppTheme.secondaryPurple.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCycleHealthScore(CycleProvider cycleProvider) {
    final allEntries = cycleProvider.cycleEntries.toList();
    int healthScore = 0;
    
    if (allEntries.isEmpty) {
      // No data - show base score
      healthScore = 50;
    } else {
      // 1. Cycle Regularity (30 points)
      final regularityScore = _calculateRegularityScore(cycleProvider);
      healthScore += regularityScore;
      
      // 2. Entry Frequency (20 points)
      final entryFrequencyScore = _calculateEntryFrequencyScore(allEntries);
      healthScore += entryFrequencyScore;
      
      // 3. Sleep Quality (20 points)
      final sleepScore = _calculateSleepScore(allEntries);
      healthScore += sleepScore;
      
      // 4. Water Intake (15 points)
      final waterScore = _calculateWaterScore(allEntries);
      healthScore += waterScore;
      
      // 5. Stress Management (10 points)
      final stressScore = _calculateStressScore(allEntries);
      healthScore += stressScore;
      
      // 6. Symptom Tracking (5 points)
      final symptomScore = _calculateSymptomTrackingScore(allEntries);
      healthScore += symptomScore;
    }
    
    // Ensure score is within bounds
    healthScore = healthScore.clamp(0, 100);
    
    final scoreColor = healthScore >= 80 ? AppTheme.successGreen :
                      healthScore >= 60 ? AppTheme.warningOrange :
                      AppTheme.errorRed;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.1),
            scoreColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.health_and_safety,
                  color: scoreColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.health_score.title'.tr(),
                style: ResponsiveTheme.getResponsiveTitleStyle(
                  context,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: AppTheme.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Center(
            child: Column(
              children: [
                Text(
                  '$healthScore',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'cycle_tracking.health_score.out_of'.tr(),
                  style: ResponsiveTheme.getResponsiveBodyStyle(
                    context,
                    fontWeight: FontWeight.w500,
                  ).copyWith(
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getHealthScoreDescription(healthScore),
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthScoreDescription(int score) {
    if (score >= 90) return 'cycle_tracking.health_score.excellent'.tr();
    if (score >= 80) return 'cycle_tracking.health_score.very_good'.tr();
    if (score >= 70) return 'cycle_tracking.health_score.good'.tr();
    if (score >= 60) return 'cycle_tracking.health_score.fair'.tr();
    if (score >= 50) return 'cycle_tracking.health_score.needs_improvement'.tr();
    return 'cycle_tracking.health_score.poor'.tr();
  }

  int _calculateRegularityScore(CycleProvider cycleProvider) {
    // Calculate based on cycle regularity
    final cyclesTracked = cycleProvider.cyclesTracked;
    if (cyclesTracked < 2) return 10; // Not enough data
    
    // If cycles are tracked, give points based on consistency
    // This is a simplified version - you can enhance with actual cycle length variance
    if (cyclesTracked >= 6) return 30;
    if (cyclesTracked >= 3) return 25;
    return 15;
  }

  int _calculateEntryFrequencyScore(List<CycleEntry> entries) {
    if (entries.isEmpty) return 0;
    
    // Check entries in last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentEntries = entries.where((e) => e.date.isAfter(thirtyDaysAgo)).length;
    
    // Ideal: 15+ entries in 30 days (tracking most days)
    if (recentEntries >= 15) return 20;
    if (recentEntries >= 10) return 15;
    if (recentEntries >= 5) return 10;
    if (recentEntries >= 2) return 5;
    return 0;
  }

  int _calculateSleepScore(List<CycleEntry> entries) {
    final sleepEntries = entries.where((e) => e.sleepHours != null).toList();
    if (sleepEntries.isEmpty) return 10; // Neutral score if no data
    
    final avgSleep = sleepEntries.map((e) => e.sleepHours!).reduce((a, b) => a + b) / sleepEntries.length;
    
    // Optimal: 7-9 hours
    if (avgSleep >= 7 && avgSleep <= 9) return 20;
    if (avgSleep >= 6 && avgSleep < 7) return 15;
    if (avgSleep > 9 && avgSleep <= 10) return 15;
    if (avgSleep >= 5 && avgSleep < 6) return 10;
    if (avgSleep > 10) return 10;
    return 5; // Less than 5 hours
  }

  int _calculateWaterScore(List<CycleEntry> entries) {
    final waterEntries = entries.where((e) => e.waterIntake != null).toList();
    if (waterEntries.isEmpty) return 7; // Neutral score if no data
    
    final avgWater = waterEntries.map((e) => e.waterIntake!).reduce((a, b) => a + b) / waterEntries.length;
    // Convert ml to liters for easier comparison
    final avgWaterLiters = avgWater / 1000;
    
    // Optimal: 2-3 liters per day
    if (avgWaterLiters >= 2 && avgWaterLiters <= 3) return 15;
    if (avgWaterLiters >= 1.5 && avgWaterLiters < 2) return 12;
    if (avgWaterLiters > 3 && avgWaterLiters <= 4) return 12;
    if (avgWaterLiters >= 1 && avgWaterLiters < 1.5) return 8;
    if (avgWaterLiters > 4) return 8;
    return 5; // Less than 1 liter
  }

  int _calculateStressScore(List<CycleEntry> entries) {
    final stressEntries = entries.where((e) => e.stressLevel != null).toList();
    if (stressEntries.isEmpty) return 5; // Neutral score if no data
    
    final avgStress = stressEntries.map((e) => e.stressLevel!).reduce((a, b) => a + b) / stressEntries.length;
    
    // Lower stress is better (1-10 scale)
    if (avgStress <= 3) return 10; // Low stress
    if (avgStress <= 5) return 8; // Moderate stress
    if (avgStress <= 7) return 5; // High stress
    return 3; // Very high stress
  }

  int _calculateSymptomTrackingScore(List<CycleEntry> entries) {
    if (entries.isEmpty) return 0;
    
    // Check how many entries have symptoms tracked
    final entriesWithSymptoms = entries.where((e) => e.symptoms.isNotEmpty).length;
    final trackingRate = entriesWithSymptoms / entries.length;
    
    // Good tracking: 50%+ entries have symptoms
    if (trackingRate >= 0.5) return 5;
    if (trackingRate >= 0.3) return 3;
    if (trackingRate >= 0.1) return 2;
    return 0;
  }

  Widget _buildMedicationTracker(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    final medicationEntries = recentEntries.where((e) => e.tookMedication && e.medicationNotes != null && e.medicationNotes!.isNotEmpty).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryPurple.withOpacity(0.1),
            AppTheme.secondaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: AppTheme.secondaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'cycle_tracking.medication.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: AppTheme.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (medicationEntries.isNotEmpty)
            ...medicationEntries.take(5).map((entry) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: AppTheme.secondaryPurple,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.medicationNotes!,
                        style: ResponsiveTheme.getResponsiveBodyStyle(
                          context,
                          fontWeight: FontWeight.w500,
                        ).copyWith(
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ),
                    Text(
                      '${entry.date.day}/${entry.date.month}',
                      style: ResponsiveTheme.getResponsiveCaptionStyle(
                        context,
                      ).copyWith(
                        color: AppTheme.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ).toList()
          else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.medication_outlined,
                    color: Colors.white.withOpacity(0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'cycle_tracking.medication.no_medications'.tr(),
                    style: ResponsiveTheme.getResponsiveBodyStyle(
                      context,
                    ).copyWith(
                      color: AppTheme.textSecondaryDark,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Additional Professional Features
  Widget _buildMoodStressTracker(CycleProvider cycleProvider) {
    // Get more entries to find stress level data
    final allEntries = cycleProvider.cycleEntries.toList();
    final recentEntries = allEntries.take(10).toList();
    final moodEntries = recentEntries.where((e) => e.mood != null).toList();
    // Look for stress level in all entries, not just recent 10
    final stressEntries = allEntries.where((e) => e.stressLevel != null).toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPink.withOpacity(0.1),
            AppTheme.accentTeal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.sentiment_satisfied,
                  color: AppTheme.primaryPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'cycle_tracking.mood_stress.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: AppTheme.textPrimaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildMoodStressItem(
                  'cycle_tracking.mood_stress.average_mood'.tr(),
                  moodEntries.isNotEmpty ? _getAverageMood(moodEntries) : 'N/A',
                  Icons.sentiment_satisfied,
                  AppTheme.primaryPink,
                ),
              ),
              Expanded(
                child: _buildMoodStressItem(
                  'cycle_tracking.mood_stress.stress_level'.tr(),
                  stressEntries.isNotEmpty ? '${_getAverageStress(stressEntries)}/10' : 'N/A',
                  Icons.flash_on,
                  AppTheme.accentTeal,
                ),
              ),
            ],
          ),
          
          if (moodEntries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'cycle_tracking.moods.recent_moods'.tr(),
              style: ResponsiveTheme.getResponsiveBodyStyle(
                context,
                fontWeight: FontWeight.w500,
              ).copyWith(
                color: AppTheme.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: moodEntries.take(5).map((entry) => 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryPink.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${entry.mood} (${entry.date.day}/${entry.date.month})',
                    style: TextStyle(
                      color: AppTheme.primaryPink,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodStressItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: ResponsiveTheme.getResponsiveBodyStyle(
            context,
            fontWeight: FontWeight.w700,
          ).copyWith(
            color: AppTheme.textPrimaryDark,
          ),
        ),
        Text(
          label,
          style: ResponsiveTheme.getResponsiveCaptionStyle(
            context,
            fontWeight: FontWeight.w500,
          ).copyWith(
            color: AppTheme.textSecondaryDark,
          ),
        ),
      ],
    );
  }

  String _getAverageMood(List<CycleEntry> entries) {
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      moodCounts[entry.mood!] = (moodCounts[entry.mood!] ?? 0) + 1;
    }
    final mostCommon = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return mostCommon.key;
  }

  double _getAverageStress(List<CycleEntry> entries) {
    final total = entries.map((e) => e.stressLevel!).reduce((a, b) => a + b);
    return (total / entries.length).roundToDouble();
  }

  Widget _buildSleepWaterAnalytics(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries.take(10).toList();
    final sleepEntries = recentEntries.where((e) => e.sleepHours != null).toList();
    final waterEntries = recentEntries.where((e) => e.waterIntake != null).toList();
    
    final avgSleep = sleepEntries.isNotEmpty 
        ? sleepEntries.map((e) => e.sleepHours!).reduce((a, b) => a + b) / sleepEntries.length
        : 0.0;
    final avgWater = waterEntries.isNotEmpty
        ? waterEntries.map((e) => e.waterIntake!).reduce((a, b) => a + b) / waterEntries.length
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.1),
            AppTheme.successGreen.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: AppTheme.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
                              Text(
                  'cycle_tracking.sleep_water.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildSleepWaterItem(
                  'cycle_tracking.sleep_water.avg_sleep'.tr(),
                  '${avgSleep.toStringAsFixed(1)}h',
                  Icons.bedtime,
                  AppTheme.accentTeal,
                  _getSleepQuality(avgSleep),
                ),
              ),
              Expanded(
                child: _buildSleepWaterItem(
                  'cycle_tracking.sleep_water.avg_water'.tr(),
                  '${(avgWater / 1000).toStringAsFixed(1)}L',
                  Icons.water_drop,
                  AppTheme.successGreen,
                  _getWaterQuality(avgWater),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Sleep Quality Chart Section - Clickable
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SleepWaterScreen(),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cycle_tracking.sleep_water.sleep_quality_chart.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentTeal.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: AppTheme.accentTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sleepEntries.isNotEmpty 
                              ? 'cycle_tracking.sleep_water.sleep_quality_chart.subtitle'.tr()
                              : 'cycle_tracking.sleep_water.sleep_quality_chart.no_data'.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.accentTeal,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Water Intake Trends Section - Clickable
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SleepWaterScreen(),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cycle_tracking.sleep_water.water_intake_chart.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: AppTheme.successGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          waterEntries.isNotEmpty
                              ? 'cycle_tracking.sleep_water.water_intake_chart.subtitle'.tr()
                              : 'cycle_tracking.sleep_water.water_intake_chart.no_data'.tr(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppTheme.successGreen,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepWaterItem(String label, String value, IconData icon, Color color, String quality) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: ResponsiveTheme.getResponsiveBodyStyle(
            context,
            fontWeight: FontWeight.w700,
          ).copyWith(
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          quality,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getSleepQuality(double hours) {
    if (hours >= 8) return 'cycle_tracking.sleep_water.sleep_quality.excellent'.tr();
    if (hours >= 7) return 'cycle_tracking.sleep_water.sleep_quality.good'.tr();
    if (hours >= 6) return 'cycle_tracking.sleep_water.sleep_quality.fair'.tr();
    return 'cycle_tracking.sleep_water.sleep_quality.poor'.tr();
  }

  String _getWaterQuality(double ml) {
    if (ml >= 2500) return 'cycle_tracking.sleep_water.water_intake.excellent'.tr();
    if (ml >= 2000) return 'cycle_tracking.sleep_water.water_intake.good'.tr();
    if (ml >= 1500) return 'cycle_tracking.sleep_water.water_intake.fair'.tr();
    return 'cycle_tracking.sleep_water.water_intake.low'.tr();
  }

  Widget _buildPeriodFlowTracker(CycleProvider cycleProvider) {
    final recentEntries = cycleProvider.cycleEntries
        .where((e) => e.isPeriodDay && e.periodFlow != null)
        .take(5)
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.errorRed.withOpacity(0.1),
            AppTheme.primaryPink.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.errorRed.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'cycle_tracking.flow.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: AppTheme.textPrimaryDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (recentEntries.isNotEmpty)
            ...recentEntries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppTheme.errorRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Text(
                        '${entry.date.day}/${entry.date.month}',
                        style: ResponsiveTheme.getResponsiveBodyStyle(
                          context,
                          fontWeight: FontWeight.w500,
                        ).copyWith(
                          color: AppTheme.textPrimaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getFlowColor(entry.periodFlowDescription).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getFlowColor(entry.periodFlowDescription),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          entry.periodFlowDescription,
                          style: TextStyle(
                            color: _getFlowColor(entry.periodFlowDescription),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList()
          else
            Center(
              child: Text(
                'cycle_tracking.flow.no_data'.tr(),
                style: ResponsiveTheme.getResponsiveBodyStyle(
                  context,
                ).copyWith(
                  color: AppTheme.textSecondaryDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getFlowColor(String flow) {
    switch (flow.toLowerCase()) {
      case 'light':
        return AppTheme.successGreen;
      case 'medium':
        return AppTheme.warningOrange;
      case 'heavy':
        return AppTheme.errorRed;
      default:
        return AppTheme.primaryPink;
    }
  }

  Widget _buildCycleIrregularityAlerts(CycleProvider cycleProvider) {
    final recentCycles = cycleProvider.cycleEntries
        .where((e) => e.isPeriodDay)
        .toList();
    
    final alerts = <String>[];
    
    if (recentCycles.length >= 2) {
      final cycleLengths = <int>[];
      for (int i = 1; i < recentCycles.length; i++) {
        final days = recentCycles[i].date.difference(recentCycles[i-1].date).inDays;
        cycleLengths.add(days);
      }
      
      final avgCycleLength = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
      final variance = cycleLengths.map((length) => (length - avgCycleLength).abs()).reduce((a, b) => a + b) / cycleLengths.length;
      
      if (variance > 5) {
        alerts.add('cycle_tracking.alerts.irregularity'.tr());
      }
      if (avgCycleLength < 21 || avgCycleLength > 35) {
        alerts.add('cycle_tracking.alerts.abnormal_length'.tr());
      }
    }
    
    if (recentCycles.isEmpty) {
      alerts.add('cycle_tracking.alerts.no_data'.tr());
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningOrange.withOpacity(0.1),
            AppTheme.errorRed.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'cycle_tracking.alerts.title'.tr(),
                style: ResponsiveTheme.getResponsiveTitleStyle(
                  context,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: AppTheme.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (alerts.isNotEmpty)
            ...alerts.map((alert) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.warningOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert,
                        style: ResponsiveTheme.getResponsiveBodyStyle(
                          context,
                          fontWeight: FontWeight.w500,
                        ).copyWith(
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList()
          else
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successGreen,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'cycle_tracking.alerts.all_regular'.tr(),
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWellnessTips(CycleProvider cycleProvider) {
    final currentPhase = cycleProvider.currentPhase;
    final tips = _getWellnessTipsForPhase(currentPhase);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successGreen.withOpacity(0.1),
            AppTheme.accentTeal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: AppTheme.successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'cycle_tracking.wellness_tips.title'.tr(),
                  style: ResponsiveTheme.getResponsiveTitleStyle(
                    context,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    color: AppTheme.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          ...tips.map((tip) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.successGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: ResponsiveTheme.getResponsiveBodyStyle(
                        context,
                        fontWeight: FontWeight.w500,
                      ).copyWith(
                        color: AppTheme.textPrimaryDark,
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

  List<String> _getWellnessTipsForPhase(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return [
          'cycle_tracking.wellness_tips.menstrual.tip1'.tr(),
          'cycle_tracking.wellness_tips.menstrual.tip2'.tr(),
          'cycle_tracking.wellness_tips.menstrual.tip3'.tr(),
          'cycle_tracking.wellness_tips.menstrual.tip4'.tr(),
        ];
      case CyclePhase.follicular:
        return [
          'cycle_tracking.wellness_tips.follicular.tip1'.tr(),
          'cycle_tracking.wellness_tips.follicular.tip2'.tr(),
          'cycle_tracking.wellness_tips.follicular.tip3'.tr(),
          'cycle_tracking.wellness_tips.follicular.tip4'.tr(),
        ];
      case CyclePhase.ovulation:
        return [
          'cycle_tracking.wellness_tips.ovulation.tip1'.tr(),
          'cycle_tracking.wellness_tips.ovulation.tip2'.tr(),
          'cycle_tracking.wellness_tips.ovulation.tip3'.tr(),
          'cycle_tracking.wellness_tips.ovulation.tip4'.tr(),
        ];
      case CyclePhase.luteal:
        return [
          'cycle_tracking.wellness_tips.luteal.tip1'.tr(),
          'cycle_tracking.wellness_tips.luteal.tip2'.tr(),
          'cycle_tracking.wellness_tips.luteal.tip3'.tr(),
          'cycle_tracking.wellness_tips.luteal.tip4'.tr(),
        ];
      default:
        return [
          'Track your cycle regularly',
          'Maintain a healthy lifestyle',
          'Listen to your body',
          'Consult healthcare provider if needed',
        ];
      }
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



