import 'package:flutter/material.dart';
import 'package:ovumate/utils/responsive_layout.dart';
import 'package:ovumate/utils/screen_size_tester.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/widgets/cycle_statistics_widget.dart';

class OverflowTestScreen extends StatefulWidget {
  const OverflowTestScreen({super.key});

  @override
  State<OverflowTestScreen> createState() => _OverflowTestScreenState();
}

class _OverflowTestScreenState extends State<OverflowTestScreen> {
  int _currentTestIndex = 0;
  final List<Widget> _testWidgets = [];

  @override
  void initState() {
    super.initState();
    _initializeTestWidgets();
  }

  void _initializeTestWidgets() {
    _testWidgets.addAll([
      _buildResponsiveGridTest(),
      _buildResponsiveRowTest(),
      _buildTextOverflowTest(),
      _buildDialogOverflowTest(),
      _buildTabNavigationTest(),
      _buildCycleStatisticsTest(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overflow Prevention Tests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.screen_share),
            onPressed: () => _showSizeTestDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Test selector
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTestButton('Grid Test', 0),
                  _buildTestButton('Row Test', 1),
                  _buildTestButton('Text Test', 2),
                  _buildTestButton('Dialog Test', 3),
                  _buildTestButton('Tab Test', 4),
                  _buildTestButton('Stats Test', 5),
                ],
              ),
            ),
          ),
          
          // Current test widget
          Expanded(
            child: _testWidgets[_currentTestIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, int index) {
    final isSelected = _currentTestIndex == index;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: () => setState(() => _currentTestIndex = index),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppTheme.primaryPink : Colors.grey.shade300,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildResponsiveGridTest() {
    return ResponsiveLayout.responsiveContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responsive Grid Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ResponsiveLayout.responsiveGrid(
            context: context,
            children: List.generate(6, (index) => _buildTestCard('Card ${index + 1}')),
            mobileCrossAxisCount: 1,
            tabletCrossAxisCount: 2,
            desktopCrossAxisCount: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveRowTest() {
    return ResponsiveLayout.responsiveContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Responsive Row/Column Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ResponsiveLayout.responsiveRow(
            context: context,
            children: [
              Expanded(child: _buildTestCard('Left Section')),
              Expanded(child: _buildTestCard('Right Section')),
            ],
            mobileChildren: [
              _buildTestCard('Top Section'),
              _buildTestCard('Bottom Section'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextOverflowTest() {
    return ResponsiveLayout.responsiveContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text Overflow Prevention Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildLongTextTest(),
          const SizedBox(height: 16),
          _buildFlexibleTextTest(),
        ],
      ),
    );
  }

  Widget _buildLongTextTest() {
    const longText = 'This is a very long text that should demonstrate overflow prevention. '
        'It contains multiple sentences and should wrap properly on different screen sizes '
        'without causing any overflow issues. The text should be contained within its boundaries.';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Long Text Test:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              longText,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlexibleTextTest() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flexible Text Test:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'This text should be flexible and adapt to the available space without overflowing.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Fixed',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOverflowTest() {
    return ResponsiveLayout.responsiveContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dialog Overflow Prevention Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showTestDialog(),
            child: const Text('Show Responsive Dialog'),
          ),
          const SizedBox(height: 16),
          Text(
            'This test shows how dialogs adapt to different screen sizes. '
            'The dialog content should never overflow the screen boundaries.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigationTest() {
    return ResponsiveLayout.responsiveContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tab Navigation Overflow Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildResponsiveTabs(),
        ],
      ),
    );
  }

  Widget _buildResponsiveTabs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(child: _buildTab('Overview')),
              Expanded(child: _buildTab('Calendar')),
              Expanded(child: _buildTab('Statistics')),
              Expanded(child: _buildTab('Lifestyle')),
            ],
          );
        } else {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTab('Overview'),
                _buildTab('Calendar'),
                _buildTab('Statistics'),
                _buildTab('Lifestyle'),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildTab(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primaryPink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCycleStatisticsTest() {
    return ResponsiveLayout.responsiveContainer(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cycle Statistics Widget Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const Expanded(
            child: CycleStatisticsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryPink.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star,
            color: AppTheme.primaryPink,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.primaryPink,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responsive Dialog Test'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Text(
                'This dialog demonstrates responsive sizing. '
                'It should adapt to different screen sizes without overflow.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ResponsiveLayout.responsiveGrid(
                  context: context,
                  children: List.generate(4, (index) => _buildTestCard('Dialog Card ${index + 1}')),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSizeTestDialog() {
    ScreenSizeTester.showSizeTestDialog(
      context,
      _testWidgets[_currentTestIndex],
    );
  }
}

