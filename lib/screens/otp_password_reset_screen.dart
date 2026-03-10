import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:ovumate/providers/auth_provider.dart';

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
    // Validate OTP field
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the 6-digit verification code from your email';
      });
      return;
    }

    // Validate password fields
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final supabase = Supabase.instance.client;

      // Verify OTP code using AuthProvider
      final otpCode = _otpController.text.trim();
      debugPrint('🔵 Verifying OTP code: $otpCode for email: ${widget.email}');

      final isOtpValid = await authProvider.verifyOtpCode(widget.email, otpCode);
      
      if (!isOtpValid) {
        final errorMsg = authProvider.errorMessage ?? 'Invalid or expired verification code';
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
        return;
      }

      debugPrint('✅ OTP code verified successfully');

      // Now we need to create a recovery session to update password
      // Use Supabase's password reset flow
      // First, send another reset email to get a valid recovery session
      // Or use the OTP verification to create a temporary session
      
      // Alternative: Use Supabase's resetPasswordForEmail and then verify with OTP
      // For now, let's use a workaround: verify OTP, then use password reset link
      
      // Since we verified OTP, we can now allow password reset
      // We'll use Supabase's updateUser but we need a session
      // Let's create a recovery session by using the reset password flow
      
      // Actually, after OTP verification, we can directly update password
      // But we need admin privileges or a valid session
      // Let's use Supabase's RPC function or direct update
      
      // For password reset with OTP, we need to:
      // 1. Verify OTP (done)
      // 2. Get a recovery token or create a session
      // 3. Update password
      
      // Workaround: After OTP verification, trigger password reset email again
      // and use that session, OR use Supabase admin API
      
      // Better approach: After OTP verification, we can update password directly
      // if we have the user's email verified
      
      // Let's try to update password using the email
      final newPassword = _passwordController.text.trim();
      debugPrint('🔵 Updating password for ${widget.email}...');

      // Use Supabase's admin API or RPC function to update password
      // Since we verified OTP, we can trust this request
      // Try using RPC function first
      try {
        await supabase.rpc('update_password_after_otp', params: {
          'user_email': widget.email,
          'otp_code': otpCode,
          'new_password': newPassword,
        });
        debugPrint('✅ Password updated successfully via RPC');
      } catch (rpcError) {
        debugPrint('⚠️ RPC method failed: $rpcError');
        
        // Fallback: Use password reset email flow
        // Send reset email to get a recovery session, then update password
        debugPrint('🔵 Using fallback method: sending password reset email...');
        
        // Send password reset email to get a valid recovery session
        await supabase.auth.resetPasswordForEmail(
          widget.email,
          redirectTo: 'io.supabase.ovumate://reset-password',
        );
        
        // Wait a bit for email processing
        await Future.delayed(const Duration(seconds: 2));
        
        // Since we can't automatically get the session from email,
        // we'll need user to click the link OR use admin API
        // For now, show message that user needs to use the email link
        throw Exception('Please check your email for the password reset link. The OTP code has been verified.');
      }

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
      debugPrint('❌ Error in password reset flow: $e');
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

                // OTP Input - Always show for code-based verification
                TextField(
                  controller: _otpController,
                  enabled: !_isLoading,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '6-Digit Verification Code',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    hintText: 'Enter 6-digit code from email',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.pin, color: Colors.white.withOpacity(0.7)),
                    helperText: 'Enter the 6-digit code sent to your email',
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
                  style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.bold),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    // Auto-format: only allow digits
                    if (value.length > 6) {
                      _otpController.text = value.substring(0, 6);
                      _otpController.selection = TextSelection.collapsed(offset: 6);
                    }
                  },
                ),
                const SizedBox(height: 20),
                
                if (_isTokenVerified) ...[
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
                  'Enter the 6-digit verification code from your email, then set your new password.',
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

