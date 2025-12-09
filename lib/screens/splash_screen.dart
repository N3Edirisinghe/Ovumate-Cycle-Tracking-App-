import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/screens/login_screen.dart';
import 'package:ovumate/screens/auth_screen.dart';
import 'package:ovumate/screens/main_navigation.dart';
import 'package:ovumate/screens/language_selection_screen.dart';
import 'package:ovumate/screens/pin_verification_screen.dart';
import 'package:ovumate/utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false; // Prevent duplicate navigation

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    debugPrint('🟢 ========== SPLASH SCREEN STARTED ==========');
    
    // Start animations immediately for faster UI
    _logoController.forward();
    _fadeController.forward();
    _scaleController.forward();
    
    // ABSOLUTE FALLBACK: Navigate after 3 seconds NO MATTER WHAT
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasNavigated) {
        debugPrint('🚨 ABSOLUTE EMERGENCY: Force navigating after 3 seconds - NO EXCEPTIONS');
        _navigateToLogin();
      }
    });
    
    // Start authentication in parallel (non-blocking)
    _initializeAuthentication();
  }

  void _initializeAuthentication() async {
    debugPrint('🔵 Starting authentication initialization...');
    
    // IMMEDIATE NAVIGATION - Maximum 1.5 seconds wait time
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_hasNavigated) {
        debugPrint('⏰ Maximum auth wait time reached (1.5s) - navigating now');
        _navigateToLogin();
      }
    });
    
    try {
      debugPrint('🔵 Starting fast authentication check...');
      
      // Check language in background (non-blocking)
      unawaited(SharedPreferences.getInstance().then((prefs) {
        final selectedLanguage = prefs.getString('selected_language');
        if (selectedLanguage == null) {
          prefs.setString('selected_language', 'en');
          if (mounted && context.mounted) {
            context.setLocale(const Locale('en'));
          }
        }
      }).catchError((e) {
        debugPrint('⚠️ Language setup error: $e');
      }));

      if (!mounted) {
        _navigateToLogin();
        return;
      }
      
      // Wait minimal time for build to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) {
        _navigateToLogin();
        return;
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Try to initialize auth with short timeout
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _hasNavigated) return;
        
        try {
          debugPrint('🔵 Initializing auth provider...');
          await authProvider.initialize().timeout(
            const Duration(milliseconds: 500),
            onTimeout: () {
              debugPrint('⚠️ Auth init timeout (500ms) - navigating immediately');
              if (mounted && !_hasNavigated) {
                _navigateToLogin();
              }
            },
          );
          debugPrint('✅ Auth initialization completed');
          
          // Navigate after initialization
          if (mounted && !_hasNavigated) {
            final prefs = await SharedPreferences.getInstance();
            final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
            if (isLoggedIn && authProvider.currentUser != null) {
              debugPrint('✅ User logged in - checking PIN...');
              _checkAndNavigateWithPin();
            } else {
              debugPrint('✅ No user session - navigating to auth screen...');
              _navigateToLogin();
            }
          }
        } catch (e) {
          debugPrint('⚠️ Auth initialization error: $e - navigating immediately');
          if (mounted && !_hasNavigated) {
            _navigateToLogin();
          }
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('❌ Authentication initialization failed: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Always navigate to login on error
      if (mounted && !_hasNavigated) {
        debugPrint('✅ Navigating to login screen due to error');
        _navigateToLogin();
      }
    }
  }

  void _navigateToLogin() {
    // Prevent duplicate navigation calls
    if (_hasNavigated || !mounted) {
      if (_hasNavigated) {
        debugPrint('⚠️ Navigation already in progress - skipping');
      }
      if (!mounted) {
        debugPrint('⚠️ Widget not mounted - cannot navigate');
      }
      return;
    }
    
    _hasNavigated = true;
    debugPrint('🟢 ========== NAVIGATING TO AUTH SCREEN (Sign In/Sign Up) ==========');
    
    // Navigate immediately
    try {
      debugPrint('🔵 Calling Navigator.pushReplacement...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            debugPrint('🔵 Building AuthScreen widget...');
            return const AuthScreen();
          },
        ),
      );
      debugPrint('✅ Navigation to auth screen completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error in navigation: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      
      // Fallback - use post frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          debugPrint('⚠️ Widget unmounted in fallback navigation');
          return;
        }
        
        try {
          debugPrint('🔵 Attempting fallback navigation in post frame...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
          debugPrint('✅ Fallback navigation completed');
        } catch (finalError) {
          debugPrint('❌ Final navigation fallback failed: $finalError');
          _hasNavigated = false; // Reset on failure to allow retry
        }
      });
    }
  }

  Future<void> _checkAndNavigateWithPin() async {
    final prefs = await SharedPreferences.getInstance();
    final isPinEnabled = prefs.getBool('pin_enabled') ?? false;
    final savedPin = prefs.getString('user_pin') ?? '';

    if (isPinEnabled && savedPin.isNotEmpty) {
      // PIN is enabled, show PIN verification screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                PinVerificationScreen(
              onVerified: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const MainNavigation(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                );
              },
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    } else {
      // PIN not enabled, navigate directly to main app
      _navigateToMainApp();
    }
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigation(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToLanguageSelection() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LanguageSelectionScreen(isInitialSelection: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryPink.withOpacity( 0.08),
              AppTheme.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top section with logo and branding
              Expanded(
                flex: 4,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Professional animated logo
                      ScaleTransition(
                        scale: _logoAnimation,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryPink.withOpacity( 0.4),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: AppTheme.primaryPink.withOpacity( 0.2),
                                blurRadius: 60,
                                offset: const Offset(0, 30),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/ov1.jpeg.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('⚠️ Error loading logo: $error');
                                // Return simple fallback immediately
                                return Container(
                                  width: 140,
                                  height: 140,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'OV',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              // Add cache to prevent loading issues
                              cacheWidth: 140,
                              cacheHeight: 140,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Professional app name with fade animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'OvuMate',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppTheme.primaryPink,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Professional tagline with slide animation
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Your Personal Cycle Companion',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Middle section with decorative elements
              Expanded(
                flex: 1,
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDecorativeDot(0),
                        const SizedBox(width: 8),
                        _buildDecorativeDot(1),
                        const SizedBox(width: 8),
                        _buildDecorativeDot(2),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom section with loading indicator
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Professional loading indicator
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.primaryPink.withOpacity( 0.2),
                              width: 2,
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryPink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Professional loading text
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        'Setting up your experience...',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom padding
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.primaryPink.withOpacity( 0.3 + (index * 0.2)),
        shape: BoxShape.circle,
      ),
    );
  }
}


