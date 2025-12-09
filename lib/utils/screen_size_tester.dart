import 'package:flutter/material.dart';

class ScreenSizeTester {
  static const Map<String, Size> screenSizes = {
    'Small Phone': const Size(320, 568),    // iPhone SE, small Android
    'Medium Phone': const Size(375, 667),   // iPhone 6/7/8
    'Large Phone': const Size(414, 896),    // iPhone X/XS/11 Pro
    'Extra Large Phone': const Size(480, 800), // Large Android phones
    'Small Tablet': const Size(768, 1024),  // iPad Mini
    'Medium Tablet': const Size(834, 1112), // iPad Air
    'Large Tablet': const Size(1024, 1366), // iPad Pro 11"
    'Desktop': const Size(1440, 900),       // Laptop
    'Large Desktop': const Size(1920, 1080), // Desktop monitor
  };

  static Widget testOnMultipleSizes({
    required Widget child,
    required BuildContext context,
    List<String>? specificSizes,
    bool showSizeLabel = true,
  }) {
    final sizesToTest = specificSizes ?? screenSizes.keys.toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Size Testing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Force rebuild to test different sizes
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: sizesToTest.map((sizeName) {
            final size = screenSizes[sizeName]!;
            return _buildSizeTestContainer(
              sizeName: sizeName,
              size: size,
              child: child,
              showSizeLabel: showSizeLabel,
            );
          }).toList(),
        ),
      ),
    );
  }

  static Widget _buildSizeTestContainer({
    required String sizeName,
    required Size size,
    required Widget child,
    required bool showSizeLabel,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSizeLabel)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Text(
                '$sizeName (${size.width.toInt()}x${size.height.toInt()})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: MediaQuery(
                data: MediaQueryData(size: size),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget responsiveTest({
    required Widget child,
    required BuildContext context,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        
        return Stack(
          children: [
            child,
            // Overlay showing current screen size
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${width.toInt()}x${height.toInt()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static void showSizeTestDialog(BuildContext context, Widget child) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: testOnMultipleSizes(
            context: context,
            child: child,
            specificSizes: ['Small Phone', 'Medium Phone', 'Large Phone', 'Small Tablet'],
          ),
        ),
      ),
    );
  }
}

class OverflowDetector extends StatelessWidget {
  final Widget child;
  final String? label;

  const OverflowDetector({
    super.key,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            child,
            // Overflow indicator
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            if (label != null)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

