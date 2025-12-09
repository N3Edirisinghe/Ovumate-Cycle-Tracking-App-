import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ovumate/screens/cycle_tracking_screen.dart';
import 'package:ovumate/screens/ovulation_calculator_screen.dart';
import 'package:ovumate/screens/health_ai_screen.dart';
import 'package:ovumate/screens/wellness_screen.dart';
import 'package:ovumate/screens/settings_screen.dart';
import 'package:ovumate/utils/responsive_layout.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CycleTrackingScreen(),
    const OvulationCalculatorScreen(),
    const HealthAIScreen(),
    const WellnessScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ResponsiveLayout.responsiveContainer(
        context: context,
        mobilePadding: EdgeInsets.zero,
        tabletPadding: EdgeInsets.zero,
        desktopPadding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, -8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: ResponsiveLayout.isMobile(context) ? 70 : 80,
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveLayout.isMobile(context) ? 8 : 16,
                vertical: ResponsiveLayout.isMobile(context) ? 8 : 10,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use Flexible for each nav item to prevent overflow
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(child: _buildNavItem(0, Icons.calendar_today_rounded, 'navigation.cycle'.tr())),
                      Flexible(child: _buildNavItem(1, Icons.favorite_rounded, 'navigation.ovulation'.tr())),
                      Flexible(child: _buildNavItem(2, Icons.chat_bubble_rounded, 'navigation.ai'.tr())),
                      Flexible(child: _buildNavItem(3, Icons.article_rounded, 'navigation.articles'.tr())),
                      Flexible(child: _buildNavItem(4, Icons.settings_rounded, 'navigation.settings'.tr())),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 6 : 12,
          vertical: isMobile ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: isMobile ? 22 : 24,
            ),
            if (!isMobile) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


