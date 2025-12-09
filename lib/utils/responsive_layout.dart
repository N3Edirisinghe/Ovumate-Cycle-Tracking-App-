import 'package:flutter/material.dart';

class ResponsiveLayout {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getResponsiveWidth(BuildContext context, {double mobile = 1.0, double tablet = 0.8, double desktop = 0.6}) {
    if (isMobile(context)) return MediaQuery.of(context).size.width * mobile;
    if (isTablet(context)) return MediaQuery.of(context).size.width * tablet;
    return MediaQuery.of(context).size.width * desktop;
  }

  static Widget responsiveRow({
    required BuildContext context,
    required List<Widget> children,
    required List<Widget> mobileChildren,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    if (isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: mobileChildren,
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  static Widget responsiveGrid({
    required BuildContext context,
    required List<Widget> children,
    int mobileCrossAxisCount = 1,
    int tabletCrossAxisCount = 2,
    int desktopCrossAxisCount = 3,
    double mobileChildAspectRatio = 1.5,
    double tabletChildAspectRatio = 1.2,
    double desktopChildAspectRatio = 1.0,
    double crossAxisSpacing = 16.0,
    double mainAxisSpacing = 16.0,
  }) {
    int crossAxisCount;
    double childAspectRatio;
    
    if (isMobile(context)) {
      crossAxisCount = mobileCrossAxisCount;
      childAspectRatio = mobileChildAspectRatio;
    } else if (isTablet(context)) {
      crossAxisCount = tabletCrossAxisCount;
      childAspectRatio = tabletChildAspectRatio;
    } else {
      crossAxisCount = desktopCrossAxisCount;
      childAspectRatio = desktopChildAspectRatio;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }

  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
    double? mobileMargin,
    double? tabletMargin,
    double? desktopMargin,
  }) {
    EdgeInsets padding;
    double margin;
    
    if (isMobile(context)) {
      padding = mobilePadding ?? const EdgeInsets.all(16);
      margin = mobileMargin ?? 16;
    } else if (isTablet(context)) {
      padding = tabletPadding ?? const EdgeInsets.all(20);
      margin = tabletMargin ?? 20;
    } else {
      padding = desktopPadding ?? const EdgeInsets.all(24);
      margin = desktopMargin ?? 24;
    }

    return Container(
      margin: EdgeInsets.all(margin),
      padding: padding,
      child: child,
    );
  }

  static Widget scrollableIfNeeded({
    required BuildContext context,
    required Widget child,
    Axis scrollDirection = Axis.horizontal,
    bool alwaysScrollable = false,
  }) {
    if (alwaysScrollable || isMobile(context)) {
      return SingleChildScrollView(
        scrollDirection: scrollDirection,
        child: child,
      );
    }
    return child;
  }

  static Widget flexibleIfNeeded({
    required BuildContext context,
    required Widget child,
    bool useFlexible = true,
  }) {
    if (useFlexible && !isMobile(context)) {
      return Flexible(child: child);
    }
    return child;
  }

  static Widget expandedIfNeeded({
    required BuildContext context,
    required Widget child,
    bool useExpanded = true,
  }) {
    if (useExpanded && !isMobile(context)) {
      return Expanded(child: child);
    }
    return child;
  }
}

class OverflowPrevention {
  static Widget preventOverflow({
    required Widget child,
    bool wrapWithSingleChildScrollView = false,
    ScrollPhysics? physics,
    EdgeInsets? padding,
  }) {
    if (wrapWithSingleChildScrollView) {
      return SingleChildScrollView(
        physics: physics,
        padding: padding,
        child: child,
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          ),
          child: child,
        );
      },
    );
  }

  static Widget flexibleText({
    required String text,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Flexible(
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
      ),
    );
  }

  static Widget safeExpanded({
    required Widget child,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

