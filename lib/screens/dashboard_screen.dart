import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/providers/wellness_provider.dart';
import 'package:ovumate/widgets/cycle_overview_card.dart';
import 'package:ovumate/widgets/prediction_card.dart';
import 'package:ovumate/widgets/quick_action_card.dart';
import 'package:ovumate/widgets/wellness_summary_card.dart';
import 'package:ovumate/widgets/cycle_statistics_widget.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/screens/add_entry_screen.dart';
import 'package:ovumate/screens/notifications_screen.dart';
import 'package:ovumate/screens/cycle_insights_screen.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/models/cycle_entry.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
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
    _initializeData();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  Future<void> _initializeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);
    final wellnessProvider = Provider.of<WellnessProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await cycleProvider.initialize(authProvider.currentUser!.id);
      await wellnessProvider.initialize();
      await notificationProvider.loadPendingNotifications();
    }
  }

  void _createSampleNotifications() async {
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    await notificationProvider.createSampleNotifications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Created 3 sample notifications! Check the notification button.'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Professional App bar with enhanced design
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryPink,
              leading: Container(
                margin: const EdgeInsets.only(left: 16),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/ov1.jpeg.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.currentUser;
                    return Text(
                      user?.firstName != null ? 'Hi, ${user!.firstName}!' : 'Welcome!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    );
                  },
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryPink,
                        AppTheme.secondaryPurple,
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.15),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative elements
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () {
                      // TODO: Navigate to settings
                    },
                  ),
                ),
              ],
            ),
            
            // Dashboard content with professional spacing
            SliverToBoxAdapter(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 0,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      
                      // Professional welcome message with personalized greeting
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            final user = authProvider.currentUser;
                            final welcomeText = user?.firstName != null
                                ? 'Welcome back, ${user!.firstName}! 👋 Track your cycle, stay healthy'
                                : 'Welcome back! 👋 Track your cycle, stay healthy';
                            
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPink.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.insights_outlined,
                                      color: AppTheme.primaryPink,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      welcomeText,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Color(0xFF1A252F), // Darker text color
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Quick Actions Section with professional layout
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPink,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Quick Actions',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: QuickActionCard(
                                      title: 'Add Entry',
                                      icon: Icons.add_circle_outline,
                                      color: AppTheme.primaryPink,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AddEntryScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: QuickActionCard(
                                      title: 'View Calendar',
                                      icon: Icons.calendar_month_outlined,
                                      color: AppTheme.secondaryPurple,
                                      onTap: () {
                                        // TODO: Navigate to calendar view
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: QuickActionCard(
                                      title: 'Cycle Insights',
                                      icon: Icons.analytics_outlined,
                                      color: AppTheme.accentTeal,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const CycleInsightsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: QuickActionCard(
                                      title: 'Test Notifications',
                                      icon: Icons.notifications_active,
                                      color: AppTheme.warningOrange,
                                      onTap: () {
                                        _createSampleNotifications();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Cycle Overview Section with professional styling
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
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
                                    'Cycle Overview',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Consumer<CycleProvider>(
                                builder: (context, cycleProvider, child) {
                                  if (cycleProvider.isLoading) {
                                    return Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(20),
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
                                  return CycleOverviewCard(
                                    currentPhase: cycleProvider.currentPhase ?? CyclePhase.unknown,
                                    averageCycleLength: cycleProvider.averageCycleLength,
                                    averagePeriodLength: cycleProvider.averagePeriodLength,
                                    cyclesTracked: cycleProvider.cyclesTracked,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Predictions Section with professional styling
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
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
                                    'Predictions',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Consumer<CycleProvider>(
                                builder: (context, cycleProvider, child) {
                                  if (cycleProvider.isLoading) {
                                    return Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.accentTeal,
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  // Show predictions if available
                                  final predictions = <Widget>[];
                                  
                                  if (cycleProvider.nextPeriodStart != null) {
                                    predictions.add(
                                      PredictionCard(
                                        title: 'Next Period',
                                        date: cycleProvider.nextPeriodStart!,
                                        icon: Icons.calendar_today,
                                        color: AppTheme.primaryPink,
                                      ),
                                    );
                                  }
                                  
                                  if (cycleProvider.nextOvulationDate != null) {
                                    if (predictions.isNotEmpty) {
                                      predictions.add(const SizedBox(height: 12));
                                    }
                                    predictions.add(
                                      PredictionCard(
                                        title: 'Ovulation',
                                        date: cycleProvider.nextOvulationDate!,
                                        icon: Icons.egg,
                                        color: AppTheme.secondaryPurple,
                                      ),
                                    );
                                  }
                                  
                                  if (predictions.isEmpty) {
                                    return Container(
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: AppTheme.textTertiaryLight,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No predictions available',
                                              style: TextStyle(
                                                color: Color(0xFF5D6D7E), // Darker text color
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return Column(children: predictions);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Cycle Statistics Section
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
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
                                    'cycle_tracking.statistics.title'.tr(),
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const CycleStatisticsWidget(),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Wellness Section with professional styling
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
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
                                  Expanded(
                                    child: Text(
                                      'Wellness Articles',
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPink.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: Navigate to wellness screen
                                      },
                                      child: Text(
                                        'View All',
                                        style: TextStyle(
                                          color: AppTheme.primaryPink,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Consumer<WellnessProvider>(
                                builder: (context, wellnessProvider, child) {
                                  if (wellnessProvider.isLoading) {
                                    return Container(
                                      height: 220,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.successGreen,
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final articles = wellnessProvider.featuredArticles;
                                  if (articles.isEmpty) {
                                    return Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceElevated,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.borderLight,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.article_outlined,
                                              color: AppTheme.textTertiaryLight,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'No articles available',
                                              style: TextStyle(
                                                color: Color(0xFF5D6D7E), // Darker text color
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  return SizedBox(
                                    height: 220,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: articles.length,
                                      itemBuilder: (context, index) {
                                        final article = articles[index];
                                        return Container(
                                          width: 300,
                                          margin: EdgeInsets.only(
                                            right: index < articles.length - 1 ? 20 : 0,
                                          ),
                                          child: Card(
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                                          Icons.article_outlined,
                                                          color: AppTheme.primaryPink,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          article.category.categoryDisplayName,
                                                          style: TextStyle(
                                                            color: Color(0xFF5D6D7E), // Darker text color
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      if (article.isNew)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: AppTheme.successGreen.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            'NEW',
                                                            style: TextStyle(
                                                              color: AppTheme.successGreen,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    article.title,
                                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: -0.2,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    article.summary,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Color(0xFF5D6D7E), // Darker text color
                                                    ),
                                                    maxLines: 3,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const Spacer(),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 16,
                                                        color: AppTheme.textTertiaryLight,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${article.readTime} min read',
                                                        style: TextStyle(
                                                          color: Color(0xFF5D6D7E), // Darker text color
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      if (article.rating > 0) ...[
                                                        Icon(
                                                          Icons.star,
                                                          size: 16,
                                                          color: AppTheme.warningOrange,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          article.rating.toString(),
                                                          style: TextStyle(
                                                            color: Color(0xFF5D6D7E), // Darker text color
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Add bottom padding to prevent overflow with FAB
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Professional Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPink.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEntryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'Add Entry',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          backgroundColor: AppTheme.primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
