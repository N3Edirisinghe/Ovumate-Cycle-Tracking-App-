import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  // Beautiful Modern Color Palette for Teenage Girls
  static const Color primaryPink = Color(0xFFE55A8A); // Darker pink
  static const Color secondaryPurple = Color(0xFF8B4DA6); // Darker purple
  static const Color accentTeal = Color(0xFF00B894); // Darker teal
  static const Color successGreen = Color(0xFF27AE60); // Darker green
  static const Color warningOrange = Color(0xFFE67E22); // Darker orange
  static const Color errorRed = Color(0xFFC0392B); // Darker red
  
  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF5F5F5); // Slightly darker white
  static const Color surfaceLight = Color(0xFFFEFEFE); // Slightly darker white
  static const Color surfaceElevated = Color(0xFFF0F2FF); // Darker blue-white
  static const Color surfaceCard = Color(0xFFFEFEFE); // Slightly darker card white
  static const Color textPrimaryLight = Color(0xFF1A252F); // Darker blue-gray
  static const Color textSecondaryLight = Color(0xFF5D6D7E); // Darker medium gray
  static const Color textTertiaryLight = Color(0xFF95A5A6); // Darker light gray
  static const Color borderLight = Color(0xFFD5E8F7); // Darker blue border
  static const Color dividerLight = Color(0xFFE5E8ED); // Darker divider
  
  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F0F1A); // Very deep navy
  static const Color surfaceDark = Color(0xFF1A1A2E); // Darker blue
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondaryDark = Color(0xFFCCD6E0); // Brighter blue-gray
  static const Color textTertiaryDark = Color(0xFFA0B4C8); // Brighter medium blue-gray
  static const Color borderDark = Color(0xFF1E2A3A); // Darker blue border
  static const Color dividerDark = Color(0xFF2A3A4A); // Darker divider

  // Beautiful Gradient Colors
  static const Color gradientStart = Color(0xFFE55A8A); // Darker pink
  static const Color gradientMiddle = Color(0xFF8B4DA6); // Darker purple
  static const Color gradientEnd = Color(0xFF00B894); // Darker teal
  
  // Special Accent Colors
  static const Color roseGold = Color(0xFFD4A5A9); // Darker rose gold
  static const Color softLavender = Color(0xFFD4D4F0); // Darker lavender
  static const Color mintCream = Color(0xFFE0F5E0); // Darker mint cream
  static const Color peachPink = Color(0xFFE6A5B0); // Darker peach pink
  static const Color skyBlue = Color(0xFF6BB6D4); // Darker sky blue

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryPink,
        secondary: secondaryPurple,
        tertiary: accentTeal,
        surface: surfaceLight,
        background: backgroundLight,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        onBackground: textPrimaryLight,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
      
      // Beautiful App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: primaryPink,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: primaryPink,
          size: 24,
        ),
      ),
      
      // Beautiful Card Theme
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: primaryPink.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surfaceCard,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Beautiful Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: primaryPink.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Beautiful Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPink,
          side: const BorderSide(color: primaryPink, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Beautiful Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          color: textTertiaryLight,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: textSecondaryLight,
          fontSize: 16,
        ),
      ),

      // Beautiful Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimaryLight,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimaryLight,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimaryLight,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: 0,
          height: 1.4,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: 0,
          height: 1.4,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimaryLight,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimaryLight,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimaryLight,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondaryLight,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryLight,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryLight,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiaryLight,
          letterSpacing: 0.1,
          height: 1.4,
        ),
      ),

      // Beautiful Icon Theme
      iconTheme: const IconThemeData(
        color: primaryPink,
        size: 24,
      ),

      // Beautiful Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),

      // Beautiful Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryPink,
        unselectedItemColor: textTertiaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),

      // Beautiful Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink;
          }
          return textTertiaryLight;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink.withOpacity(0.3);
          }
          return textTertiaryLight.withOpacity(0.3);
        }),
      ),

      // Beautiful Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Beautiful Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink;
          }
          return textTertiaryLight;
        }),
      ),

      // Beautiful Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryPink,
        inactiveTrackColor: textTertiaryLight.withOpacity(0.3),
        thumbColor: primaryPink,
        overlayColor: primaryPink.withOpacity(0.2),
        valueIndicatorColor: primaryPink,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Beautiful Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryPink,
        linearTrackColor: surfaceElevated,
        circularTrackColor: surfaceElevated,
      ),

      // Beautiful Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerLight,
        thickness: 1,
        space: 1,
      ),

      // Beautiful Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primaryPink.withOpacity(0.2),
        disabledColor: textTertiaryLight.withOpacity(0.2),
        labelStyle: GoogleFonts.poppins(
          color: textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryPink,
        secondary: secondaryPurple,
        tertiary: accentTeal,
        surface: surfaceDark,
        background: backgroundDark,
        error: errorRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        onBackground: textPrimaryDark,
        onError: Colors.white,
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
      
      // Beautiful Dark App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: primaryPink,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: primaryPink,
          size: 24,
        ),
      ),
      
      // Beautiful Dark Card Theme
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: primaryPink.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: surfaceDark,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Beautiful Dark Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: primaryPink.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Beautiful Dark Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryPink,
          side: const BorderSide(color: primaryPink, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Beautiful Dark Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: borderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          color: textTertiaryDark,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.poppins(
          color: textSecondaryDark,
          fontSize: 16,
        ),
      ),

      // Beautiful Dark Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimaryDark,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimaryDark,
          letterSpacing: -0.2,
          height: 1.4,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: 0,
          height: 1.4,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: 0,
          height: 1.4,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimaryDark,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimaryDark,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimaryDark,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondaryDark,
          letterSpacing: 0.2,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimaryDark,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondaryDark,
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textTertiaryDark,
          letterSpacing: 0.1,
          height: 1.4,
        ),
      ),

      // Beautiful Dark Icon Theme
      iconTheme: const IconThemeData(
        color: primaryPink,
        size: 24,
      ),

      // Beautiful Dark Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),

      // Beautiful Dark Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryPink,
        unselectedItemColor: textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),

      // Beautiful Dark Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink;
          }
          return textTertiaryDark;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink.withOpacity(0.3);
          }
          return textTertiaryDark.withOpacity(0.3);
        }),
      ),

      // Beautiful Dark Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Beautiful Dark Radio Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryPink;
          }
          return textTertiaryDark;
        }),
      ),

      // Beautiful Dark Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryPink,
        inactiveTrackColor: textTertiaryDark.withOpacity(0.3),
        thumbColor: primaryPink,
        overlayColor: primaryPink.withOpacity(0.2),
        valueIndicatorColor: primaryPink,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Beautiful Dark Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryPink,
        linearTrackColor: surfaceDark,
        circularTrackColor: surfaceDark,
      ),

      // Beautiful Dark Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerDark,
        thickness: 1,
        space: 1,
      ),

      // Beautiful Dark Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: primaryPink.withOpacity(0.2),
        disabledColor: textTertiaryDark.withOpacity(0.2),
        labelStyle: GoogleFonts.poppins(
          color: textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  // Beautiful Gradient Themes
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle, gradientEnd],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient get softGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [roseGold, softLavender, mintCream],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient get sunsetGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [peachPink, primaryPink, skyBlue],
    stops: [0.0, 0.5, 1.0],
  );

  // Beautiful Shadow Themes
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryPink.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryPink.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryPink.withOpacity(0.3),
      blurRadius: 12,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
}

// Enhanced ResponsiveTheme with beautiful styling
class ResponsiveTheme {
  static double getResponsiveFontSize(BuildContext context, {double? baseSize}) {
    final width = MediaQuery.of(context).size.width;
    baseSize ??= 16.0;
    
    if (width < 600) return baseSize * 0.9; // Mobile
    if (width < 1200) return baseSize * 1.0; // Tablet
    return baseSize * 1.1; // Desktop
  }

  static double getResponsivePadding(BuildContext context, {double? basePadding}) {
    final width = MediaQuery.of(context).size.width;
    basePadding ??= 16.0;
    
    if (width < 600) return basePadding * 0.8; // Mobile
    if (width < 1200) return basePadding * 1.0; // Tablet
    return basePadding * 1.2; // Desktop
  }

  static double getResponsiveSpacing(BuildContext context, {double? baseSpacing}) {
    final width = MediaQuery.of(context).size.width;
    baseSpacing ??= 16.0;
    
    if (width < 600) return baseSpacing * 0.8; // Mobile
    if (width < 1200) return baseSpacing * 1.0; // Tablet
    return baseSpacing * 1.2; // Desktop
  }

  static EdgeInsets getResponsiveEdgeInsets(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) {
      final responsiveAll = getResponsivePadding(context, basePadding: all);
      return EdgeInsets.all(responsiveAll);
    }
    
    final responsiveHorizontal = getResponsivePadding(context, basePadding: horizontal ?? 16);
    final responsiveVertical = getResponsivePadding(context, basePadding: vertical ?? 16);
    
    return EdgeInsets.symmetric(
      horizontal: responsiveHorizontal,
      vertical: responsiveVertical,
    );
  }

  static double getResponsiveBorderRadius(BuildContext context, {double? baseRadius}) {
    final width = MediaQuery.of(context).size.width;
    baseRadius ??= 20.0;
    
    if (width < 600) return baseRadius * 0.8; // Mobile
    if (width < 1200) return baseRadius * 1.0; // Tablet
    return baseRadius * 1.1; // Desktop
  }

  // Beautiful Responsive Text Sizes
  static double getResponsiveTitleSize(BuildContext context) {
    return getResponsiveFontSize(context, baseSize: 22);
  }

  static double getResponsiveSubtitleSize(BuildContext context) {
    return getResponsiveFontSize(context, baseSize: 18);
  }

  static double getResponsiveBodySize(BuildContext context) {
    return getResponsiveFontSize(context, baseSize: 16);
  }

  static double getResponsiveCaptionSize(BuildContext context) {
    return getResponsiveFontSize(context, baseSize: 14);
  }

  // Beautiful Responsive Text Styles
  static TextStyle getResponsiveTextStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    TextOverflow? overflow,
  }) {
    final responsiveFontSize = fontSize ?? getResponsiveFontSize(context);
    
    return TextStyle(
      fontSize: responsiveFontSize,
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      letterSpacing: letterSpacing ?? 0.2,
      height: height ?? 1.5,
      decoration: decoration,
      overflow: overflow,
    );
  }

  // Predefined Beautiful Responsive Text Styles
  static TextStyle getResponsiveTitleStyle(
    BuildContext context, {
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return getResponsiveTextStyle(
      context,
      fontSize: getResponsiveTitleSize(context),
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      letterSpacing: letterSpacing ?? -0.2,
      height: 1.3,
    );
  }

  static TextStyle getResponsiveSubtitleStyle(
    BuildContext context, {
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return getResponsiveTextStyle(
      context,
      fontSize: getResponsiveSubtitleSize(context),
      fontWeight: fontWeight ?? FontWeight.w500,
      color: color,
      letterSpacing: letterSpacing ?? 0,
      height: 1.4,
    );
  }

  static TextStyle getResponsiveBodyStyle(
    BuildContext context, {
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return getResponsiveTextStyle(
      context,
      fontSize: getResponsiveBodySize(context),
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing ?? 0.2,
          height: 1.5,
    );
  }

  static TextStyle getResponsiveCaptionStyle(
    BuildContext context, {
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return getResponsiveTextStyle(
      context,
      fontSize: getResponsiveCaptionSize(context),
      fontWeight: fontWeight ?? FontWeight.w400,
      color: color,
      letterSpacing: letterSpacing ?? 0.2,
      height: 1.4,
    );
  }
}

// Beautiful Screen Fitter for responsive layouts
class ScreenFitter {
  static Widget fitToScreen(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }

  static EdgeInsets responsivePadding(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    return ResponsiveTheme.getResponsiveEdgeInsets(
      context,
      horizontal: horizontal,
      vertical: vertical,
      all: all,
    );
  }

  static EdgeInsets responsiveMargin(BuildContext context, {
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) {
      final responsiveAll = ResponsiveTheme.getResponsiveSpacing(context, baseSpacing: all);
      return EdgeInsets.all(responsiveAll);
    }
    
    final responsiveHorizontal = ResponsiveTheme.getResponsiveSpacing(context, baseSpacing: horizontal ?? 16);
    final responsiveVertical = ResponsiveTheme.getResponsiveSpacing(context, baseSpacing: vertical ?? 16);
    
    return EdgeInsets.symmetric(
      horizontal: responsiveHorizontal,
      vertical: responsiveVertical,
    );
  }
}

