import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/constants.dart';

class OtpPasswordResetScreen extends StatefulWidget {
  final String email;

  const OtpPasswordResetScreen({
    super.key,
    required this.email,
  });

  @override
  State<OtpPasswordResetScreen> createState() => _OtpPasswordResetScreenState();
}

class _OtpPasswordResetScreenState extends State<OtpPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isTokenVerified = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;
      
      // Only auto-verify if we have both a session AND the user email matches
      // This ensures we only auto-verify if it's actually a password recovery session
      if (session != null && user != null && user.email == widget.email) {
        debugPrint('✅ Found existing session from email link for ${widget.email}');
        setState(() {
          _isTokenVerified = true;
        });
      } else {
        debugPrint('🔵 No valid session found, showing OTP field');
        debugPrint('🔵 Session exists: ${session != null}');
        debugPrint('🔵 User exists: ${user != null}');
        if (user != null) {
          debugPrint('🔵 User email: ${user.email}, Expected: ${widget.email}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error checking session: $e');
      // Don't auto-verify on error, show OTP field instead
    }
  }

  Future<void> _verifyOtpAndResetPassword() async {
    // If token already verified (from email link), skip OTP verification
    if (!_isTokenVerified) {
      // Validate OTP field if token not verified
      if (_otpController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please enter the verification code from your email';
        });
        return;
      }
    }

    // Validate password fields
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Verify token/URL if not already verified
      if (!_isTokenVerified) {
        final tokenOrUrl = _otpController.text.trim();
        debugPrint('🔵 Processing token/URL: $tokenOrUrl');
        debugPrint('🔵 Email: ${widget.email}');

        try {
          // Try to parse as URL first
          Uri? uri;
          try {
            uri = Uri.parse(tokenOrUrl);
          } catch (e) {
            debugPrint('⚠️ Not a valid URL, trying as token...');
          }

          // If it's a URL, try to get session from it
          if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme == 'io.supabase.ovumate')) {
            debugPrint('🔵 Detected URL format, extracting session...');
            await supabase.auth.getSessionFromUrl(uri);
            debugPrint('✅ Session established from URL');
          } else {
            // If it's just a token, construct a proper URL
            debugPrint('🔵 Constructing callback URL with token...');
            final callbackUrl = Uri.parse('${Constants.supabaseUrl}/auth/v1/callback#access_token=$tokenOrUrl&type=recovery');
            await supabase.auth.getSessionFromUrl(callbackUrl);
            debugPrint('✅ Session established from token');
          }

          // Check if session was created
          final session = supabase.auth.currentSession;
          if (session == null) {
            throw Exception('Failed to verify token. Please click the email link instead.');
          }

          debugPrint('✅ Token/URL verified successfully');
          setState(() {
            _isTokenVerified = true;
          });
        } catch (e) {
          debugPrint('⚠️ Error verifying token/URL: $e');
          setState(() {
            _errorMessage = 'Invalid or expired verification code. Please click the email link or request a new password reset email.';
            _isLoading = false;
          });
          return;
        }
      }

      // Verify we have a session
      final session = supabase.auth.currentSession;
      if (session == null) {
        throw Exception('Session not found. Please verify your code again.');
      }

      // Now update the password
      final newPassword = _passwordController.text.trim();
      debugPrint('🔵 Updating password...');

      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      debugPrint('✅ Password updated successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully! Please login with your new password.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to login screen
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 ========== Building OtpPasswordResetScreen ==========');
    debugPrint('🔵 Email: ${widget.email}');
    debugPrint('🔵 Token verified: $_isTokenVerified');
    debugPrint('🔵 Loading: $_isLoading');
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppTheme.surfaceDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Email display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reset password for:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              widget.email,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // OTP Input (only show if token not verified)
                if (!_isTokenVerified) ...[
                  TextField(
                    controller: _otpController,
                    enabled: true,
                    readOnly: false,
                    autofocus: false,
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      hintText: 'Enter verification code from email',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.pin, color: Colors.white.withOpacity(0.7)),
                      helperText: 'Click the email link OR paste the full email link URL here',
                      helperStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.primaryPink, width: 2),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    maxLines: 1,
                    onChanged: (value) {
                      // Allow typing
                    },
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Show success message if token already verified
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Email Verified',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You can now set your new password',
                                style: TextStyle(
                                  color: Colors.green.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // New Password Input
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primaryPink),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirm Password Input
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppTheme.primaryPink),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                  ),
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Reset Password Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtpAndResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Info text
                Text(
                  _isTokenVerified
                      ? 'Set your new password below.'
                      : 'Enter the verification code from your email link, then set your new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

