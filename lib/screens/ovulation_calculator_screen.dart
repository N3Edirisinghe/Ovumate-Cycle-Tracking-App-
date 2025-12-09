import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/responsive_layout.dart';
import 'package:ovumate/screens/language_selection_screen.dart';
import 'package:provider/provider.dart';

class OvulationCalculatorScreen extends StatefulWidget {
  const OvulationCalculatorScreen({super.key});

  @override
  State<OvulationCalculatorScreen> createState() => _OvulationCalculatorScreenState();
}

class _OvulationCalculatorScreenState extends State<OvulationCalculatorScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _lastPeriodController = TextEditingController();
  final _cycleLengthController = TextEditingController(text: '28');
  
  DateTime? _selectedDate;
  int _cycleLength = 28;
  bool _hasCalculated = false;
  Map<String, DateTime> _calculatedDates = {};

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lastPeriodController.dispose();
    _cycleLengthController.dispose();
    super.dispose();
  }
  
  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryPink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              onSurfaceVariant: Colors.grey[700],
              outline: Colors.grey[400],
              secondary: AppTheme.primaryPink.withOpacity(0.1),
              onSecondary: AppTheme.primaryPink,
            ),
            textTheme: Theme.of(context).textTheme.copyWith(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black),
              bodySmall: TextStyle(color: Colors.grey[700]),
              titleLarge: TextStyle(color: Colors.black),
              titleMedium: TextStyle(color: Colors.black),
              titleSmall: TextStyle(color: Colors.black),
              labelLarge: TextStyle(color: Colors.black),
              labelMedium: TextStyle(color: Colors.black),
              labelSmall: TextStyle(color: Colors.grey[700]),
            ),
            dialogBackgroundColor: Colors.white,
            scaffoldBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _lastPeriodController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }
  
  Future<void> _calculateOvulation() async {
    if (_selectedDate == null) {
      _showErrorSnackBar('ovulation.error.select_date'.tr());
      return;
    }

    try {
      _cycleLength = int.parse(_cycleLengthController.text);
      if (_cycleLength < 21 || _cycleLength > 35) {
        _showErrorSnackBar('ovulation.error.invalid_cycle'.tr());
        return;
      }
    } catch (e) {
      _showErrorSnackBar('ovulation.error.invalid_input'.tr());
      return;
    }

    final calculatedDates = _calculateFertilityDates();

    setState(() {
      _hasCalculated = true;
      _calculatedDates = calculatedDates;
    });

    await _scheduleCycleNotifications(calculatedDates);
  }
  
  Map<String, DateTime> _calculateFertilityDates() {
    final lastPeriod = _selectedDate!;
    
    // Next period start date
    final nextPeriod = lastPeriod.add(Duration(days: _cycleLength));
    
    // Ovulation date (14 days before next period)
    final ovulationDate = nextPeriod.subtract(const Duration(days: 14));
    
    // Fertile window (5 days before ovulation + ovulation day + 1 day after)
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));
    
    // Safe period (after fertile window until next period)
    final safeStart = fertileEnd.add(const Duration(days: 1));
    
    return {
      'nextPeriod': nextPeriod,
      'ovulation': ovulationDate,
      'fertileStart': fertileStart,
      'fertileEnd': fertileEnd,
      'safeStart': safeStart,
    };
  }
  
  Future<void> _scheduleCycleNotifications(Map<String, DateTime> dates) async {
    if (!mounted) return;

    try {
      final notificationProvider = context.read<NotificationProvider>();
      final nextPeriodDate = dates['nextPeriod']!;
      final safePeriodStart = dates['safeStart']!;

      await notificationProvider.scheduleNextCycleDateNotification(
        nextCycleDate: nextPeriodDate,
        title: 'Next period reminder',
        body:
            'Based on your $_cycleLength-day cycle, your next period is expected on ${_formatDate(nextPeriodDate)}.',
      );

      await notificationProvider.scheduleSafePeriodNotification(
        safePeriodStart: safePeriodStart,
        title: 'Safe period reminder',
        body:
            'Your lower fertility window begins on ${_formatDate(safePeriodStart)} and lasts until ${_formatDate(nextPeriodDate)}.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cycle notifications scheduled.'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Failed to schedule cycle notifications: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to schedule notifications right now.'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
  
  String _getDayOfWeek(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.secondaryPurple.withOpacity( 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Custom App Bar
                  _buildCustomAppBar(),
                  
                  // Main Content
                  _buildMainContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 10, isMobile ? 16 : 20, isMobile ? 16 : 20),
      child: Row(
        children: [
          Text(
            'app.title'.tr(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.notifications_outlined,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSelectionScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.locale.languageCode.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildMainContent() {
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'ovulation.calculator'.tr(),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: isMobile ? 24 : null,
            ),
          ),
          
          SizedBox(height: isMobile ? 24 : 32),
          
          // Input Section
          _buildInputSection(isMobile),
          
          SizedBox(height: isMobile ? 20 : 24),
          
          // Calculate Button
          _buildCalculateButton(),
          
          SizedBox(height: isMobile ? 20 : 24),
          
          // Results Section
          if (_hasCalculated) _buildResultsSection(isMobile),
          
          SizedBox(height: isMobile ? 30 : 40),
          
          // Information Section
          _buildInformationSection(isMobile),
          
          SizedBox(height: isMobile ? 30 : 40), // Increased bottom padding
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceCard,
            AppTheme.surfaceCard.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Last Period Start Date
          _buildDateInputField(),
          
          const SizedBox(height: 24),
          
          // Cycle Length
          _buildCycleLengthField(),
        ],
      ),
    );
  }

  Widget _buildDateInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity( 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today,
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
                    'ovulation.last_period'.tr(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '(yyyy-MM-dd)',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _lastPeriodController.text.isEmpty ? 'common.tap_to_select_date'.tr() : _lastPeriodController.text,
                    style: TextStyle(
                      color: _lastPeriodController.text.isEmpty ? Colors.grey[600] : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryPink,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleLengthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ovulation.cycle_length'.tr(),
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _cycleLengthController,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '28',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.edit,
                color: AppTheme.primaryPink,
                size: 20,
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _calculateOvulation(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryPink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: AppTheme.primaryPink.withOpacity(0.4),
        ),
        child: Text(
          'ovulation.calculate'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentTeal.withOpacity(0.15),
            AppTheme.primaryPink.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.calendar_month,
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
                      'ovulation.fertility_calendar'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'ovulation.based_on_cycle'.tr(args: [_cycleLength.toString()]),
                      style: TextStyle(
                        color: Colors.white, // More solid white for better visibility
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Results Grid
          _buildResultsGrid(),
        ],
      ),
    );
  }
  
  Widget _buildResultsGrid() {
    return Column(
      children: [
        // Next Period
        _buildResultCard(
          'ovulation.next_period'.tr(),
          _formatDate(_calculatedDates['nextPeriod']!),
          _getDayOfWeek(_calculatedDates['nextPeriod']!),
          Icons.calendar_today,
          AppTheme.primaryPink,
        ),
        
        const SizedBox(height: 16),
        
        // Ovulation
        _buildResultCard(
          'ovulation.ovulation_date'.tr(),
          _formatDate(_calculatedDates['ovulation']!),
          _getDayOfWeek(_calculatedDates['ovulation']!),
          Icons.egg,
          AppTheme.accentTeal,
        ),
        
        const SizedBox(height: 16),
        
        // Fertile Window
        _buildResultCard(
          'ovulation.fertile_window'.tr(),
          '${_formatDate(_calculatedDates['fertileStart']!)} - ${_formatDate(_calculatedDates['fertileEnd']!)}',
          'ovulation.best_conceive'.tr(),
          Icons.favorite,
          AppTheme.successGreen,
        ),
        
        const SizedBox(height: 16),
        
        // Safe Period
        _buildResultCard(
          'ovulation.safe_period'.tr(),
          '${_formatDate(_calculatedDates['safeStart']!)} - ${_formatDate(_calculatedDates['nextPeriod']!)}',
          'ovulation.low_pregnancy'.tr(),
          Icons.shield,
          AppTheme.secondaryPurple,
        ),
      ],
    );
  }
  
  Widget _buildResultCard(String title, String date, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9), // Slightly more solid white for better visibility
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationSection(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withOpacity( 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryPink.withOpacity( 0.3),
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
                  color: AppTheme.primaryPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ovulation.how_calculated'.tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ovulation.calculation_info'.tr(),
            style: TextStyle(
              color: Colors.white, // More solid white for better visibility
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
