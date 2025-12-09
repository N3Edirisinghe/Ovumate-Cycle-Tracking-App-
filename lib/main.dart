import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/providers/cycle_provider.dart';
import 'package:ovumate/providers/wellness_provider.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'package:ovumate/providers/language_provider.dart';
import 'package:ovumate/providers/theme_provider.dart';
import 'package:ovumate/screens/splash_screen.dart';
import 'package:ovumate/screens/main_navigation.dart';
import 'package:ovumate/screens/auth_screen.dart';
import 'package:ovumate/screens/otp_password_reset_screen.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/constants.dart';

void main() async {
  // Wrap everything in try-catch to prevent crashes
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize localization with error handling
    try {
      await EasyLocalization.ensureInitialized();
    } catch (e) {
      debugPrint('⚠️ EasyLocalization init error: $e - continuing anyway');
    }
    
    // Get prefs with error handling
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('⚠️ SharedPreferences error: $e - using default');
      // Create a minimal prefs object if it fails
    }
    
    // Clear cache in background (non-blocking) - use Future.microtask to avoid blocking
    if (prefs != null) {
      final prefsRef = prefs; // Store reference for closure
      Future.microtask(() {
        prefsRef.remove('cached_articles').catchError((e) {
          debugPrint('⚠️ Cache clear error: $e');
          return false;
        });
        prefsRef.remove('last_fetch_time').catchError((e) {
          debugPrint('⚠️ Cache clear error: $e');
          return false;
        });
      });
    }
    
    // Ensure prefs is not null
    if (prefs == null) {
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('⚠️ Failed to get SharedPreferences: $e');
        // Continue without prefs - app should still work
      }
    }
    
    // Initialize Supabase before running the app with timeout
    try {
      debugPrint('🔵 Initializing Supabase (startup) ...');
      await Supabase.initialize(
        url: Constants.supabaseUrl,
        anonKey: Constants.supabaseAnonKey,
      ).timeout(
        const Duration(seconds: 5),
      );
      debugPrint('✅ Supabase initialized (startup)');
    } on TimeoutException {
      debugPrint('⚠️ Supabase initialization timeout - continuing without Supabase');
      // Continue without Supabase - app should still load
    } catch (e, stackTrace) {
      debugPrint('❌ Supabase initialization failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      // Continue without Supabase - app should still load
    }
    
    // Run app after initialization (even if Supabase failed, UI should still load)
    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('si'),
          Locale('ta'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: OvuMateApp(prefs: prefs!),
      ),
    );
  } catch (e, stackTrace) {
    // Emergency fallback - run app without localization if everything fails
    debugPrint('❌ Critical error in main(): $e');
    debugPrint('❌ Stack trace: $stackTrace');
    
    // Try to run app anyway with minimal setup
    try {
      await SharedPreferences.getInstance();
      runApp(
        MaterialApp(
          title: 'OvuMate',
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Error: $e'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (finalError) {
      debugPrint('❌ Even emergency fallback failed: $finalError');
      // Last resort - just show error
      runApp(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Critical Error: Please restart the app'),
            ),
          ),
        ),
      );
    }
  }

}

// Global navigator key for deep link navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class OvuMateApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const OvuMateApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<NotificationProvider, CycleProvider>(
          create: (_) => CycleProvider(),
          update: (_, notificationProvider, cycleProvider) {
            final provider = cycleProvider ?? CycleProvider();
            provider.attachNotificationProvider(notificationProvider);
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => WellnessProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'OvuMate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const SplashScreen(),
            // Handle deep links for password reset and email confirmation
            onGenerateRoute: (settings) {
              if (settings.name != null) {
                final uri = Uri.tryParse(settings.name!);
                if (uri != null) {
                  // Handle custom deep links like io.supabase.ovumate://reset-password
                  if (uri.scheme == 'io.supabase.ovumate') {
                    _handleDeepLink(uri); // Fire and forget - will navigate after auth
                    return null;
                  }
                  // Handle HTTPS Supabase callback URLs
                  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
                      uri.host.contains('rtujdsnupkwkvnxklgzd.supabase.co') &&
                      (uri.fragment.contains('access_token') || uri.path.contains('/auth/v1/callback'))) {
                    _handleDeepLink(uri); // Fire and forget - will navigate after auth
                    return null;
                  }
                }
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

// Handle deep links for authentication
Future<void> _handleDeepLink(Uri uri) async {
  try {
    final supabase = Supabase.instance.client;
    
    debugPrint('🔵 Handling deep link: $uri');
    debugPrint('🔵 URI fragment: ${uri.fragment}');
    debugPrint('🔵 URI path: ${uri.path}');
    debugPrint('🔵 URI query: ${uri.queryParameters}');
    
    // Check if this is a password recovery link
    final isRecoveryLink = uri.fragment.contains('type=recovery') || 
                          (uri.queryParameters.containsKey('type') && 
                           uri.queryParameters['type'] == 'recovery');
    
    // Check if this is an email confirmation link
    final isEmailConfirmation = uri.fragment.contains('type=signup') ||
                                uri.fragment.contains('type=invite') ||
                                (uri.queryParameters.containsKey('type') && 
                                 (uri.queryParameters['type'] == 'signup' || 
                                  uri.queryParameters['type'] == 'invite'));
    
    debugPrint('🔵 Is recovery link: $isRecoveryLink');
    debugPrint('🔵 Is email confirmation: $isEmailConfirmation');
    
    // Handle Supabase callback URLs (most common case)
    // Handle both /auth/v1/callback and base domain with hash
    if (uri.toString().contains('rtujdsnupkwkvnxklgzd.supabase.co')) {
      // Check if it's a callback URL with access_token
      if (uri.fragment.contains('access_token') || 
          uri.path.contains('/auth/v1/callback') ||
          uri.queryParameters.containsKey('access_token')) {
        try {
          // Convert hash-based URL to proper format if needed
          Uri sessionUri = uri;
          if (uri.fragment.contains('access_token') && !uri.path.contains('/auth/v1/callback')) {
            // Convert hash fragment to proper callback URL format
            // Hash fragment should be: #access_token=...&type=recovery&...
            final fragment = uri.fragment;
            final callbackUrl = Uri.parse(
              '${Constants.supabaseUrl}/auth/v1/callback#$fragment'
            );
            sessionUri = callbackUrl;
            debugPrint('🔵 Converted hash URL to callback URL: $callbackUrl');
          }
          
          await supabase.auth.getSessionFromUrl(sessionUri);
          debugPrint('✅ Session established from URL');
          
          // For password recovery, navigate to auth screen (user needs to set new password)
          // For email confirmation, navigate to main app
          // For regular auth, navigate to main app
          if (isRecoveryLink) {
            debugPrint('🔵 Password recovery link detected - navigating to auth screen');
            await _handlePasswordRecovery();
          } else if (isEmailConfirmation) {
            debugPrint('🔵 Email confirmation detected - preparing login screen');
            await _handleEmailConfirmationSuccess();
          } else {
            debugPrint('🔵 Regular auth link - navigating to main app');
            await _handleSuccessfulAuth();
          }
        } catch (e) {
          debugPrint('⚠️ Error getting session from URL: $e');
          debugPrint('⚠️ Error details: ${e.toString()}');
          
          // Check if it's the "requested path is invalid" error
          final errorString = e.toString().toLowerCase();
          if (errorString.contains('requested path is invalid') || 
              errorString.contains('invalid') && errorString.contains('path')) {
            debugPrint('🔴 Detected "requested path is invalid" error');
            // For email confirmation, show a helpful message
            _showEmailConfirmationHelp();
            return;
          }
          
          // Try alternative approach
          try {
            // If hash-based, try constructing proper callback URL
            if (uri.fragment.isNotEmpty && uri.fragment.contains('access_token')) {
              final properUrl = Uri.parse('${Constants.supabaseUrl}/auth/v1/callback#${uri.fragment}');
              await supabase.auth.getSessionFromUrl(properUrl);
              debugPrint('✅ Session established from converted URL');
              
              if (isRecoveryLink) {
                await _handlePasswordRecovery();
              } else if (isEmailConfirmation) {
                debugPrint('🔵 Email confirmed via alternative URL - preparing login screen');
                await _handleEmailConfirmationSuccess();
              } else {
                await _handleSuccessfulAuth();
              }
            }
          } catch (e2) {
            debugPrint('⚠️ Error with alternative URL handling: $e2');
            debugPrint('⚠️ Error details: ${e2.toString()}');
            
            // Check if it's the "requested path is invalid" error again
            final errorString2 = e2.toString().toLowerCase();
            if (errorString2.contains('requested path is invalid') || 
                errorString2.contains('invalid') && errorString2.contains('path')) {
              _showEmailConfirmationHelp();
              return;
            }
            
            // Show generic error to user
            _showDeepLinkError('Failed to process password reset link. Please try requesting a new reset email.');
          }
        }
      } else {
        debugPrint('⚠️ URL does not contain access_token');
        _showDeepLinkError('Invalid password reset link. Please request a new reset email.');
      }
    }
    
    // Handle deep links like io.supabase.ovumate://reset-password
    else if (uri.scheme == 'io.supabase.ovumate') {
      // Convert deep link to Supabase callback URL format
      // The token is in the fragment, we need to handle it properly
      if (uri.fragment.contains('access_token')) {
        // Create a proper callback URL
        final callbackUrl = Uri.parse(
          '${Constants.supabaseUrl}/auth/v1/callback#${uri.fragment}'
        );
        try {
          await supabase.auth.getSessionFromUrl(callbackUrl);
          debugPrint('✅ Session established from deep link');
          
          if (isRecoveryLink) {
            await _handlePasswordRecovery();
          } else if (isEmailConfirmation) {
            debugPrint('🔵 Email confirmed via deep link - preparing login screen');
            await _handleEmailConfirmationSuccess();
          } else {
            await _handleSuccessfulAuth();
          }
        } catch (e) {
          debugPrint('⚠️ Error getting session from deep link: $e');
          _showDeepLinkError('Failed to process password reset link. Please try requesting a new reset email.');
        }
      }
    } else {
      debugPrint('⚠️ Unrecognized URL scheme: ${uri.scheme}');
      _showDeepLinkError('Invalid link format. Please use the link from your email.');
    }
  } catch (e, stackTrace) {
    debugPrint('⚠️ Error handling deep link: $e');
    debugPrint('⚠️ Stack trace: $stackTrace');
    _showDeepLinkError('An error occurred while processing the link. Please try again.');
  }
}

// Handle password recovery - navigate to OTP password reset screen
Future<void> _handlePasswordRecovery() async {
  try {
    debugPrint('🟢 Handling password recovery...');
    
    // Wait a bit for session to be fully established
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get email from session
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final email = user?.email ?? '';
    
    if (email.isEmpty) {
      debugPrint('⚠️ No email found in session, navigating to auth screen');
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
      return;
    }
    
    debugPrint('✅ Email found in session: $email');
    
    // Navigate to OTP password reset screen
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OtpPasswordResetScreen(email: email),
        ),
        (route) => route.isFirst, // Keep splash screen
      );
      debugPrint('✅ Navigated to OTP password reset screen');
    } else {
      debugPrint('⚠️ Navigator not available yet');
    }
  } catch (e) {
    debugPrint('⚠️ Error handling password recovery: $e');
    // Fallback to auth screen
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }
}

// Handle successful email confirmation links - return user to login
Future<void> _handleEmailConfirmationSuccess() async {
  try {
    debugPrint('🟣 Handling email confirmation success...');
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final email = user?.email;
    
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      try {
        await supabase.auth.signOut();
      } catch (e) {
        debugPrint('⚠️ Error signing out after confirmation: $e');
      }
      
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => AuthScreen(
            initialTabIndex: 0,
            initialMessage: 'Email verified successfully! Please sign in to continue.',
            prefillEmail: email,
          ),
        ),
        (route) => false,
      );
      debugPrint('✅ Navigated to login screen after verification');
    } else {
      debugPrint('⚠️ Navigator not available for confirmation flow');
    }
  } catch (e, stackTrace) {
    debugPrint('⚠️ Error handling email confirmation success: $e');
    debugPrint('⚠️ Stack trace: $stackTrace');
  }
}

// Show error message to user
void _showDeepLinkError(String message) {
  final navigator = navigatorKey.currentState;
  if (navigator != null) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'Password Reset Error',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      navigator.pushReplacement(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                    child: const Text('Go to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }
}

// Show specific error for "requested path is invalid" - guide user to use browser
void _showPasswordResetBrowserError() {
  final navigator = navigatorKey.currentState;
  if (navigator != null) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.grey[900],
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off, size: 80, color: Colors.orange),
                    const SizedBox(height: 24),
                    const Text(
                      'Password Reset Link Issue',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'The password reset link cannot be opened directly in the app. Please use your browser to reset your password.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'How to Reset Password:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '1. Copy the link from your email\n'
                            '2. Open it in your browser (Chrome, Safari, etc.)\n'
                            '3. Set your new password\n'
                            '4. Return to the app and login',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Go to Login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }
}

// Show help for email confirmation links that can't open in app
void _showEmailConfirmationHelp() {
  final navigator = navigatorKey.currentState;
  if (navigator != null) {
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.grey[900],
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email, size: 80, color: Colors.blue),
                    const SizedBox(height: 24),
                    const Text(
                      'Email Confirmation',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Email confirmation links must be opened in a web browser, not in the app.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'How to Verify Your Email:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '1. Open your email inbox\n'
                            '2. Find the confirmation email from OvuMate\n'
                            '3. Click the link in your BROWSER (not the app)\n'
                            '4. Your email will be verified\n'
                            '5. Return to the app and login',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tip: If you don\'t see the email, check your spam folder',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        navigator.pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Go to Login'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }
}

// Handle successful authentication after password reset
Future<void> _handleSuccessfulAuth() async {
  try {
    debugPrint('🟢 Handling successful authentication...');
    
    // Wait a bit for session to be fully established
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if user is authenticated
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      debugPrint('✅ User authenticated: ${user.email}');
      
      // Navigate to main app
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
        debugPrint('✅ Navigated to main app');
      } else {
        debugPrint('⚠️ Navigator not available yet');
      }
    } else {
      debugPrint('⚠️ User not authenticated after session establishment');
    }
  } catch (e) {
    debugPrint('⚠️ Error handling successful auth: $e');
  }
}

