import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/screens/main_navigation.dart';
import 'package:ovumate/screens/pin_verification_screen.dart';
import 'package:ovumate/screens/otp_password_reset_screen.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovumate/main.dart' show navigatorKey;

class AuthScreen extends StatefulWidget {
  final int initialTabIndex;
  final String? initialMessage;
  final String? prefillEmail;
  
  const AuthScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialMessage,
    this.prefillEmail,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = (widget.initialTabIndex >= 0 && widget.initialTabIndex < 2)
        ? widget.initialTabIndex
        : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialMessage!),
            backgroundColor: AppTheme.primaryPink,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 ========== Building AuthScreen ==========');
    debugPrint('🔵 TabController index: ${_tabController.index}');
    debugPrint('🔵 TabController length: ${_tabController.length}');
    debugPrint('🔵 Screen size: ${MediaQuery.of(context).size}');
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.secondaryPurple,
              AppTheme.primaryPink,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // App Logo and Branding
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/ov1.jpeg.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'OV',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'app.title'.tr(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SMART SECURE SUPPORTIVE',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Sign In', icon: Icon(Icons.login, size: 20)),
                    Tab(text: 'Sign Up', icon: Icon(Icons.person_add, size: 20)),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const ClampingScrollPhysics(), // Ensure tabs are swipeable
                  children: [
                    _LoginTabContent(initialEmail: widget.prefillEmail),
                    const _RegisterTabContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Login tab content - extracts just the form from LoginScreen
class _LoginTabContent extends StatelessWidget {
  final String? initialEmail;
  const _LoginTabContent({this.initialEmail});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Building LoginTabContent...');
    return Container(
      color: Colors.transparent, // Make sure container is visible
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: _LoginFormContent(initialEmail: initialEmail),
      ),
    );
  }
}

// Register tab content - extracts just the form from RegisterScreen
class _RegisterTabContent extends StatelessWidget {
  const _RegisterTabContent();

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Building RegisterTabContent...');
    return Container(
      color: Colors.transparent, // Make sure container is visible
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: const _RegisterFormContent(),
      ),
    );
  }
}

// Login form content wrapper
class _LoginFormContent extends StatefulWidget {
  final String? initialEmail;
  const _LoginFormContent({this.initialEmail});

  @override
  State<_LoginFormContent> createState() => _LoginFormContentState();
}

class _LoginFormContentState extends State<_LoginFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          final user = authProvider.currentUser;
          final welcomeMessage = user?.firstName != null 
              ? 'Welcome, ${user!.firstName}! 👋'
              : 'Welcome back! 👋';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(welcomeMessage),
              backgroundColor: AppTheme.primaryPink,
              duration: const Duration(seconds: 2),
            ),
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            // Check if PIN is enabled
            await _checkAndNavigateWithPin(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkAndNavigateWithPin(BuildContext context) async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPinEnabled = prefs.getBool('pin_enabled') ?? false;
      final savedPin = prefs.getString('user_pin') ?? '';

      if (!mounted) return;

      if (isPinEnabled && savedPin.isNotEmpty) {
        // PIN is enabled, show PIN verification screen
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PinVerificationScreen(
              onVerified: () {
                debugPrint('🔵 onVerified callback called from auth_screen');
                
                // Use postFrameCallback to ensure navigation happens after current frame
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    debugPrint('🔵 Navigating to MainNavigation using root navigator...');
                    // Use root navigator directly - doesn't require widget to be mounted
                    final rootNavigator = Navigator.of(context, rootNavigator: true);
                    rootNavigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) {
                          debugPrint('🔵 Building MainNavigation in onVerified...');
                          return const MainNavigation();
                        },
                      ),
                      (route) => false, // Remove all previous routes
                    );
                    debugPrint('✅ Navigation completed successfully');
                  } catch (e) {
                    debugPrint('❌ Error in onVerified navigation: $e');
                    // Fallback: try to get navigator from global key if available
                    try {
                      final navigator = navigatorKey.currentState;
                      if (navigator != null) {
                        navigator.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MainNavigation(),
                          ),
                          (route) => false,
                        );
                        debugPrint('✅ Navigation completed using global navigator key');
                      }
                    } catch (e2) {
                      debugPrint('❌ All navigation methods failed: $e2');
                    }
                  }
                });
              },
            ),
          ),
        );
      } else {
        // PIN not enabled, navigate directly to main app
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainNavigation(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _checkAndNavigateWithPin: $e');
      if (mounted) {
        // Fallback - navigate directly
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
          );
        } catch (e2) {
          debugPrint('Fallback navigation error: $e2');
        }
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    
    // Get the parent context before showing dialog
    final parentContext = context;
    
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text(
            'Reset Password',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your email address and we will send you a password reset link.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Please enter your email address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final email = emailController.text.trim();
                
                // Close dialog first
                Navigator.of(dialogContext).pop();
                
                // Use parent context for navigation
                _navigateToOtpScreen(parentContext, email);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToOtpScreen(BuildContext context, String email) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show loading
    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Text('Sending password reset email...'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    final success = await authProvider.resetPassword(email);
    
    // Use a small delay to ensure widget is still mounted
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted && context.mounted) {
      if (success) {
        debugPrint('🔵 Password reset email sent successfully, navigating to OTP screen...');
        debugPrint('🔵 Email: $email');
        debugPrint('🔵 Context: $context');
        
        // Navigate to OTP password reset screen
        try {
          // Use WidgetsBinding to ensure navigation happens after frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              try {
                debugPrint('🔵 Attempting navigation to OTP screen...');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      debugPrint('🔵 Building OtpPasswordResetScreen with email: $email');
                      return OtpPasswordResetScreen(email: email);
                    },
                  ),
                );
                debugPrint('✅ Navigation to OTP screen completed');
                
                // Show success message after navigation
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password reset email sent!',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please check your inbox and spam folder. If you don\'t receive it within a few minutes, please check:\n\n'
                              '1. Check spam/junk folder\n'
                              '2. Verify your email address is correct\n'
                              '3. Ensure email service is configured in Supabase Dashboard',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 8),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                });
              } catch (e, stackTrace) {
                debugPrint('❌ Error navigating to OTP screen: $e');
                debugPrint('❌ Stack trace: $stackTrace');
                // Fallback: try simple push
                try {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OtpPasswordResetScreen(email: email),
                    ),
                  );
                  debugPrint('✅ Fallback navigation (push) succeeded');
                } catch (e2) {
                  debugPrint('❌ Fallback navigation also failed: $e2');
                }
              }
            }
          });
        } catch (e) {
          debugPrint('❌ Error in post frame callback: $e');
        }
      } else {
                    final errorMsg = authProvider.errorMessage ?? 'Failed to send password reset email';
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Failed to send email',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                errorMsg + '\n\n'
                                'Possible reasons:\n'
                                '• Email not registered\n'
                                '• Supabase email not configured\n'
                                '• Too many requests (wait a few minutes)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 8),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Building LoginFormContent...');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign In',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password required';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppTheme.primaryPink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Register form content wrapper  
class _RegisterFormContent extends StatefulWidget {
  const _RegisterFormContent();

  @override
  State<_RegisterFormContent> createState() => _RegisterFormContentState();
}

class _RegisterFormContentState extends State<_RegisterFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          final errorMsg = authProvider.errorMessage?.toLowerCase() ?? '';
          final email = _emailController.text.trim();
          
          final requiresEmailConfirmation = errorMsg.contains('verification') ||
                                            errorMsg.contains('confirm') ||
                                            errorMsg.contains('check your email') ||
                                            errorMsg.contains('inbox');
          
          if (requiresEmailConfirmation) {
            if (mounted && context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => AuthScreen(
                    initialTabIndex: 0,
                    initialMessage: 'Verification email sent to $email. Once you confirm it, sign in to continue.',
                    prefillEmail: email,
                  ),
                ),
              );
            }
            return;
          } else {
            // No email confirmation required - auto login
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );
            
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigation()),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Building RegisterFormContent...');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign Up',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _firstNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              validator: (value) => value == null || value.isEmpty ? 'First name required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _lastNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Last Name',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Invalid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password required';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Confirm password required';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

