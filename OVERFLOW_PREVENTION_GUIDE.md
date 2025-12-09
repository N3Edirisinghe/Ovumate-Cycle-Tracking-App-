# Overflow Prevention Guide

This guide provides comprehensive solutions for preventing overflow issues in your Flutter app.

## Common Overflow Issues and Solutions

### 1. **Text Overflow**
```dart
// ❌ Bad - Text can overflow
Text(
  'Very long text that might overflow the container',
  style: TextStyle(fontSize: 16),
)

// ✅ Good - Text with overflow handling
Text(
  'Very long text that might overflow the container',
  style: TextStyle(fontSize: 16),
  overflow: TextOverflow.ellipsis,
  maxLines: 2,
)

// ✅ Better - Flexible text that adapts to container
Flexible(
  child: Text(
    'Very long text that might overflow the container',
    style: TextStyle(fontSize: 16),
    overflow: TextOverflow.ellipsis,
  ),
)
```

### 2. **Row/Column Overflow**
```dart
// ❌ Bad - Fixed width that can overflow
Row(
  children: [
    Container(width: 200, child: Text('Item 1')),
    Container(width: 200, child: Text('Item 2')),
    Container(width: 200, child: Text('Item 3')),
  ],
)

// ✅ Good - Responsive layout with LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return Row(
        children: [
          Expanded(child: Text('Item 1')),
          Expanded(child: Text('Item 2')),
          Expanded(child: Text('Item 3')),
        ],
      );
    } else {
      return Column(
        children: [
          Text('Item 1'),
          Text('Item 2'),
          Text('Item 3'),
        ],
      );
    }
  },
)

// ✅ Better - Using ResponsiveLayout utility
ResponsiveLayout.responsiveRow(
  context: context,
  children: [
    Expanded(child: Text('Item 1')),
    Expanded(child: Text('Item 2')),
    Expanded(child: Text('Item 3')),
  ],
  mobileChildren: [
    Text('Item 1'),
    Text('Item 2'),
    Text('Item 3'),
  ],
)
```

### 3. **GridView Overflow**
```dart
// ❌ Bad - Fixed crossAxisCount that might not fit
GridView.count(
  crossAxisCount: 3,
  childAspectRatio: 1.0,
  children: [...],
)

// ✅ Good - Responsive grid with LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
    final childAspectRatio = constraints.maxWidth > 600 ? 1.0 : 1.2;
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      children: [...],
    );
  },
)

// ✅ Better - Using ResponsiveLayout utility
ResponsiveLayout.responsiveGrid(
  context: context,
  children: [...],
  mobileCrossAxisCount: 2,
  tabletCrossAxisCount: 3,
  desktopCrossAxisCount: 4,
)
```

### 4. **Container Height Overflow**
```dart
// ❌ Bad - Fixed height that can overflow
Container(
  height: 400,
  child: ListView(...),
)

// ✅ Good - Responsive height
Container(
  height: MediaQuery.of(context).size.height * 0.6,
  child: ListView(...),
)

// ✅ Better - Using ConstrainedBox
ConstrainedBox(
  constraints: BoxConstraints(
    maxHeight: MediaQuery.of(context).size.height * 0.6,
  ),
  child: ListView(...),
)
```

### 5. **Dialog Content Overflow**
```dart
// ❌ Bad - Fixed size dialog
AlertDialog(
  content: SizedBox(
    width: 400,
    height: 300,
    child: Column(...),
  ),
)

// ✅ Good - Responsive dialog
AlertDialog(
  content: SizedBox(
    width: MediaQuery.of(context).size.width * 0.9,
    height: MediaQuery.of(context).size.height * 0.7,
    child: Column(...),
  ),
)
```

## ResponsiveLayout Utility Usage

### Basic Responsiveness
```dart
import 'package:ovumate/utils/responsive_layout.dart';

// Check screen size
if (ResponsiveLayout.isMobile(context)) {
  // Mobile-specific layout
} else if (ResponsiveLayout.isTablet(context)) {
  // Tablet-specific layout
} else {
  // Desktop-specific layout
}
```

### Responsive Grid
```dart
ResponsiveLayout.responsiveGrid(
  context: context,
  children: [
    _buildCard('Card 1'),
    _buildCard('Card 2'),
    _buildCard('Card 3'),
  ],
  mobileCrossAxisCount: 1,
  tabletCrossAxisCount: 2,
  desktopCrossAxisCount: 3,
  mobileChildAspectRatio: 1.5,
  tabletChildAspectRatio: 1.2,
  desktopChildAspectRatio: 1.0,
)
```

### Responsive Row/Column
```dart
ResponsiveLayout.responsiveRow(
  context: context,
  children: [
    Expanded(child: _buildLeftSection()),
    Expanded(child: _buildRightSection()),
  ],
  mobileChildren: [
    _buildLeftSection(),
    _buildRightSection(),
  ],
)
```

### Responsive Container
```dart
ResponsiveLayout.responsiveContainer(
  context: context,
  child: _buildContent(),
  mobilePadding: EdgeInsets.all(16),
  tabletPadding: EdgeInsets.all(20),
  desktopPadding: EdgeInsets.all(24),
)
```

## OverflowPrevention Utility Usage

### Prevent Overflow with Constraints
```dart
OverflowPrevention.preventOverflow(
  child: _buildContent(),
  wrapWithSingleChildScrollView: true,
)
```

### Safe Expanded Widget
```dart
OverflowPrevention.safeExpanded(
  child: _buildContent(),
  flex: 1,
)
```

### Flexible Text
```dart
OverflowPrevention.flexibleText(
  text: 'Very long text that needs to be flexible',
  style: TextStyle(fontSize: 16),
  maxLines: 2,
)
```

## Best Practices

### 1. **Always Use LayoutBuilder for Responsive Design**
```dart
LayoutBuilder(
  builder: (context, constraints) {
    // Use constraints.maxWidth and constraints.maxHeight
    // to make layout decisions
  },
)
```

### 2. **Use Flexible and Expanded Wisely**
```dart
// ✅ Good - Flexible content
Row(
  children: [
    Expanded(child: _buildMainContent()),
    _buildFixedSidebar(),
  ],
)

// ❌ Bad - Multiple Expanded without constraints
Row(
  children: [
    Expanded(child: _buildContent1()),
    Expanded(child: _buildContent2()),
    Expanded(child: _buildContent3()),
  ],
)
```

### 3. **Handle Long Text Properly**
```dart
// Always provide overflow handling for text
Text(
  longText,
  overflow: TextOverflow.ellipsis,
  maxLines: 2,
)
```

### 4. **Use SingleChildScrollView for Horizontal Lists**
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      _buildItem1(),
      _buildItem2(),
      _buildItem3(),
    ],
  ),
)
```

### 5. **Test on Different Screen Sizes**
- Test on small phones (320dp width)
- Test on large phones (480dp width)
- Test on tablets (600dp+ width)
- Test on landscape orientation

## Common Patterns

### Responsive Tab Navigation
```dart
Widget _buildTabs() {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return Row(
          children: [
            Expanded(child: _buildTab('Tab 1')),
            Expanded(child: _buildTab('Tab 2')),
            Expanded(child: _buildTab('Tab 3')),
          ],
        );
      } else {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTab('Tab 1'),
              _buildTab('Tab 2'),
              _buildTab('Tab 3'),
            ],
          ),
        );
      }
    },
  );
}
```

### Responsive Card Layout
```dart
Widget _buildCards() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
      final childAspectRatio = constraints.maxWidth > 600 ? 1.2 : 1.5;
      
      return GridView.count(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        children: _buildCardList(),
      );
    },
  );
}
```

## Testing Overflow Prevention

### 1. **Use Flutter Inspector**
- Check for overflow warnings in the console
- Use the Flutter Inspector to see layout bounds
- Look for red overflow indicators

### 2. **Test with Different Text Lengths**
```dart
// Test with various text lengths
final testTexts = [
  'Short',
  'Medium length text',
  'Very long text that might cause overflow issues in the UI',
  'Extremely long text that should definitely cause overflow problems if not handled properly',
];

for (final text in testTexts) {
  // Test your widget with this text
}
```

### 3. **Test with Different Screen Sizes**
```dart
// Use different device configurations in your tests
await tester.binding.setSurfaceSize(Size(320, 568)); // Small phone
await tester.binding.setSurfaceSize(Size(480, 800)); // Large phone
await tester.binding.setSurfaceSize(Size(768, 1024)); // Tablet
```

## Summary

To prevent overflow issues in your Flutter app:

1. **Always use responsive layouts** with `LayoutBuilder`
2. **Handle text overflow** with `TextOverflow.ellipsis` and `maxLines`
3. **Use the ResponsiveLayout utility** for common responsive patterns
4. **Test on different screen sizes** and orientations
5. **Use Flexible and Expanded** widgets appropriately
6. **Provide fallback layouts** for small screens
7. **Use SingleChildScrollView** for horizontal scrolling when needed

By following these guidelines and using the provided utilities, you can create a robust, overflow-free Flutter app that works well on all device sizes.

