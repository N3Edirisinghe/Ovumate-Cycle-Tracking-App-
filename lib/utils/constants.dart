class Constants {
  // App Information
  static const String appName = 'OvuMate';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your Personal Cycle Companion';
  
  // Supabase Configuration
  // IMPORTANT: Replace these with your actual Supabase project credentials
  // To get these values:
  // 1. Go to https://supabase.com
  // 2. Create a new project or use an existing one
  // 3. Go to Project Settings > API
  // 4. Copy the Project URL and anon key
  // 5. For Google Sign-In to work, also configure:
  //    - Authentication > Providers > Google (enable and add credentials)
  //    - Settings > Authentication > Redirect URLs (add io.supabase.ovumate://login-callback)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rtujdsnupkwkvnxklgzd.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0dWpkc251cGt3a3ZueGtsZ3pkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwOTE2MDUsImV4cCI6MjA3NzY2NzYwNX0.9Mq9z1U7QB9KYNU3UD-Hn6Sn5TRf8oKNXXTUdMdwdhw',
  );
  
  // App Colors
  static const int primaryColor = 0xFFE91E63;
  static const int secondaryColor = 0xFF9C27B0;
  static const int accentColor = 0xFFFF4081;
  static const int backgroundColor = 0xFFF8F9FA;
  static const int surfaceColor = 0xFFFFFFFF;
  static const int errorColor = 0xFFE53E3E;
  static const int successColor = 0xFF38A169;
  static const int warningColor = 0xFFD69E2E;
  
  // Text Colors
  static const int textPrimaryColor = 0xFF1A202C;
  static const int textSecondaryColor = 0xFF718096;
  static const int textLightColor = 0xFFA0AEC0;
  
  // Cycle Colors
  static const int periodColor = 0xFFE53E3E;
  static const int ovulationColor = 0xFF38A169;
  static const int fertileWindowColor = 0xFF3182CE;
  static const int pmsColor = 0xFFD69E2E;
  
  // Dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 56.0;
  
  // Responsive Dimensions
  static const double mobilePadding = 16.0;
  static const double tabletPadding = 20.0;
  static const double desktopPadding = 24.0;
  static const double mobileSpacing = 12.0;
  static const double tabletSpacing = 16.0;
  static const double desktopSpacing = 20.0;
  
  // Card Dimensions
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;
  static const double mobileCardPadding = 16.0;
  static const double tabletCardPadding = 20.0;
  static const double desktopCardPadding = 24.0;
  
  // Text Sizes
  static const double mobileTitleSize = 18.0;
  static const double tabletTitleSize = 20.0;
  static const double desktopTitleSize = 22.0;
  static const double mobileSubtitleSize = 14.0;
  static const double tabletSubtitleSize = 16.0;
  static const double desktopSubtitleSize = 18.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userProfileKey = 'user_profile';
  static const String cycleDataKey = 'cycle_data';
  static const String settingsKey = 'app_settings';
  static const String notificationsKey = 'notifications_enabled';
  
  // API Endpoints
  static const String baseApiUrl = 'https://api.ovumate.com';
  static const String cycleEndpoint = '/api/cycles';
  static const String wellnessEndpoint = '/api/wellness';
  static const String chatEndpoint = '/api/chat';
  
  // Notification IDs
  static const int periodReminderId = 1001;
  static const int ovulationReminderId = 1002;
  static const int medicationReminderId = 1003;
  static const int wellnessReminderId = 1004;
  static const int nextCycleDateId = 1005;
  static const int safePeriodId = 1006;
  static const int newArticleId = 1007;
  
  // Default Values
  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;
  static const int defaultLutealPhase = 14;
  
  // Feature Flags
  static const bool enablePartnerSharing = true;
  static const bool enableLifestyleTracking = true;
  static const bool enableDisorderDetection = true;
  static const bool enableAdvancedAnalytics = true;
}