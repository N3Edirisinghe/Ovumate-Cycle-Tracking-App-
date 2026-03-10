import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ovumate/models/user_profile.dart';
import 'package:ovumate/utils/constants.dart';

class AuthProvider extends ChangeNotifier {
  SupabaseClient? _supabase;
  
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  // Getters
  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  User? get supabaseUser => _supabase?.auth.currentUser;
  bool get isInitialized => _supabase != null;

  // Helper method to ensure Supabase is initialized
  Future<bool> _ensureSupabaseInitialized() async {
    if (_supabase != null) return true;
    
    debugPrint('⚠️ Supabase client is null - attempting to initialize...');
    try {
      // Try to get Supabase instance
      int attempts = 0;
      while (attempts < 5 && _supabase == null) {
        try {
          _supabase = Supabase.instance.client;
          if (_supabase != null) {
            debugPrint('✅ Supabase initialized successfully');
            return true;
          }
        } catch (e) {
          debugPrint('⚠️ Supabase not ready yet (attempt ${attempts + 1}/5): $e');
          await Future.delayed(const Duration(milliseconds: 300));
        }
        attempts++;
      }
      
      // If still null, try initializing Supabase directly
      if (_supabase == null) {
        debugPrint('⚠️ Supabase.instance.client is null - trying direct initialization...');
        try {
          await Supabase.initialize(
            url: Constants.supabaseUrl,
            anonKey: Constants.supabaseAnonKey,
          );
          _supabase = Supabase.instance.client;
          if (_supabase != null) {
            debugPrint('✅ Supabase initialized directly');
            return true;
          }
        } catch (initError) {
          debugPrint('❌ Failed to initialize Supabase: $initError');
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing Supabase: $e');
    }
    
    if (_supabase == null) {
      debugPrint('❌ Supabase client is still null after initialization attempts');
      return false;
    }
    
    return true;
  }

  // Initialize auth state
  Future<void> initialize() async {
    try {
      // Don't set loading during build - use microtask to defer
      Future.microtask(() => _setLoading(true));
      
      // Initialize Supabase client with error handling
      try {
        // Wait a bit for Supabase to be initialized (if it's still initializing)
        int attempts = 0;
        while (attempts < 3) {
          try {
            _supabase = Supabase.instance.client;
            if (_supabase != null) break;
          } catch (e) {
            debugPrint('⚠️ Supabase not ready yet (attempt ${attempts + 1}/3): $e');
            await Future.delayed(const Duration(milliseconds: 200));
          }
          attempts++;
        }
        
        if (_supabase == null) {
          debugPrint('⚠️ Supabase not initialized after attempts - continuing without auth');
          _setLoading(false);
          return; // Exit early if Supabase not available
        }
      } catch (e) {
        debugPrint('⚠️ Supabase not initialized: $e - continuing without auth');
        _setLoading(false);
        return; // Exit early if Supabase not available
      }
      
      if (_supabase == null) {
        debugPrint('⚠️ Supabase client is null - continuing without auth');
        _setLoading(false);
        return;
      }
      
      // Check if user is already signed in with valid session
      try {
        final session = _supabase!.auth.currentSession;
        final user = _supabase!.auth.currentUser;
        
        debugPrint('🔵 Checking auth state...');
        debugPrint('🔵 Session exists: ${session != null}');
        debugPrint('🔵 User exists: ${user != null}');
        
        if (session != null && user != null) {
          debugPrint('✅ Existing Supabase session detected - loading profile');
          try {
            await _loadUserProfile(user.id);
          } catch (profileError) {
            debugPrint('⚠️ Error loading profile during init: $profileError');
          }
          _isAuthenticated = true;
        } else {
          _isAuthenticated = false;
          debugPrint('✅ No active session - user needs to sign in');
        }
      } catch (e) {
        debugPrint('⚠️ Error checking current user: $e');
        _isAuthenticated = false;
      }
      
      // Listen to auth state changes with error handling
      try {
        _supabase!.auth.onAuthStateChange.listen((data) async {
          try {
            final event = data.event;
            final session = data.session;
            
            if (event == AuthChangeEvent.signedIn && session != null) {
              final user = session.user;
              debugPrint('✅ User signed in via auth state change: ${user.email}');
              
              // Load or create user profile
              try {
                await _loadUserProfile(user.id).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    debugPrint('⚠️ Load user profile timeout in listener');
                  },
                );
              } catch (e) {
                debugPrint('⚠️ Error loading profile in listener: $e');
                // Profile doesn't exist, create it from user metadata
                try {
                  final profile = UserProfile(
                    id: user.id,
                    email: user.email ?? '',
                    firstName: user.userMetadata?['full_name']?.split(' ').first ??
                               user.userMetadata?['name']?.split(' ').first,
                    lastName: user.userMetadata?['full_name']?.split(' ').length > 1
                        ? user.userMetadata!['full_name'].split(' ').sublist(1).join(' ')
                        : (user.userMetadata?['name']?.split(' ').length > 1
                            ? user.userMetadata!['name'].split(' ').sublist(1).join(' ')
                            : null),
                    profileImageUrl: user.userMetadata?['avatar_url'] ??
                                    user.userMetadata?['picture'],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  await _createUserProfile(profile);
                  _currentUser = profile;
                  debugPrint('✅ Created new user profile');
                } catch (profileError) {
                  debugPrint('⚠️ Error creating profile: $profileError');
                  // Still set authenticated even if profile creation fails
                }
              }
              
              _isAuthenticated = true;
              notifyListeners();
              debugPrint('✅ Auth state updated - user authenticated');
            } else if (event == AuthChangeEvent.signedOut) {
              debugPrint('🚪 User signed out via auth state change');
              _currentUser = null;
              _isAuthenticated = false;
              notifyListeners();
            }
          } catch (listenerError) {
            debugPrint('⚠️ Error in auth state listener: $listenerError');
          }
        });
      } catch (e) {
        debugPrint('⚠️ Error setting up auth listener: $e');
      }
      
    } catch (e) {
      debugPrint('❌ Failed to initialize authentication: $e');
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      // Ensure Supabase is initialized
      if (!await _ensureSupabaseInitialized()) {
        _setError('Authentication service not initialized. Please check your internet connection and restart the app.');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      // Prepare user metadata with name information
      final Map<String, dynamic> data = {};
      if (firstName != null && firstName.isNotEmpty) {
        data['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        data['last_name'] = lastName;
      }
      
      final trimmedEmail = email.trim();
      
      debugPrint('🔵 Attempting to sign up user: $trimmedEmail');
      
      final response = await _supabase!.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: data.isNotEmpty ? data : null, // Pass metadata to Supabase
      );
      
      debugPrint('🔵 Sign up response received');
      debugPrint('🔵 User: ${response.user?.id}');
      debugPrint('🔵 Session: ${response.session != null ? "exists" : "null"}');
      debugPrint('🔵 Email confirmed: ${response.user?.emailConfirmedAt != null}');
      
      if (response.user != null) {
        // Check if email confirmation is required
        final requiresEmailConfirmation = response.session == null;
        
        if (requiresEmailConfirmation) {
          // Email confirmation is required - but user can still try to login
          // Supabase might auto-confirm them depending on settings
          debugPrint('📧 Email confirmation may be required');
          _setError('Registration successful!\n\nYou can now log in with your email and password.\n\nNote: If you receive a confirmation email, you can ignore it or click it to verify later.');
          _isAuthenticated = false;
          notifyListeners();
          return true; // Return true because registration was successful
        } else {
          // Email confirmation not required or already confirmed - auto-login
          // Profile will be automatically created by database trigger with name from metadata
          // But we still need to load it to set currentUser
          try {
            await _loadUserProfile(response.user!.id);
          } catch (e) {
            // If trigger didn't create it yet or load failed, manually create profile
            final profile = UserProfile(
              id: response.user!.id,
              email: email.trim(),
              firstName: firstName,
              lastName: lastName,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _createUserProfile(profile);
            _currentUser = profile;
          }
          
          _isAuthenticated = true;
          notifyListeners();
          return true;
        }
      }
      
      return false;
    } on AuthException catch (e) {
      final errorMsg = e.message.toLowerCase();
      
      // Check for email rate limit
      if (errorMsg.contains('rate limit') || 
          errorMsg.contains('email rate limit exceeded') ||
          errorMsg.contains('too many requests')) {
        _setError('Email rate limit exceeded. Please wait a few minutes before trying again. This is a security measure to prevent spam.');
      } else if (errorMsg.contains('user already registered') || 
                 errorMsg.contains('already exists')) {
        _setError('This email is already registered. Please try logging in instead.');
      } else if (errorMsg.contains('invalid email')) {
        _setError('Invalid email address. Please check your email and try again.');
      } else if (errorMsg.contains('password')) {
        _setError('Password does not meet requirements. Please use a stronger password.');
      } else {
        _setError('Sign up failed: ${e.message}');
      }
      debugPrint('Sign up error: ${e.message}');
      return false;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      // Check for rate limit in generic error
      if (errorString.contains('rate limit') || 
          errorString.contains('email rate limit exceeded')) {
        _setError('Email rate limit exceeded. Please wait a few minutes before trying again.');
      } else {
        _setError('Sign up failed: $e');
      }
      debugPrint('Sign up error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Ensure Supabase is initialized
      if (!await _ensureSupabaseInitialized()) {
        _setError('Authentication service not initialized. Please check your internet connection and restart the app.');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      // Trim email to remove any spaces
      final trimmedEmail = email.trim();
      
      debugPrint('🔵 Attempting to login with email: $trimmedEmail');
      
      final response = await _supabase!.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );
      
      debugPrint('✅ Login response received');
      debugPrint('🔵 User: ${response.user?.email}');
      debugPrint('🔵 Session: ${response.session != null ? "Exists" : "Null"}');
      
      if (response.user != null) {
        debugPrint('🔵 Loading user profile for: ${response.user!.id}');
        try {
          await _loadUserProfile(response.user!.id);
          _isAuthenticated = true;
          notifyListeners();
          debugPrint('✅ Login successful - user authenticated');
          debugPrint('✅ User profile loaded - cycle data should be initialized by cycle provider');
          return true;
        } catch (profileError) {
          debugPrint('⚠️ Profile load error: $profileError');
          // Still allow login even if profile fails
          _isAuthenticated = true;
          notifyListeners();
          debugPrint('✅ Login successful (profile load failed but continuing)');
          return true;
        }
      } else {
        debugPrint('❌ Login failed - user is null');
        _setError('Login failed - no user returned');
        return false;
      }
    } on AuthException catch (e) {
      debugPrint('❌ AuthException: ${e.message}');
      debugPrint('❌ AuthException code: ${e.statusCode}');
      
      // Handle specific auth errors with better messages
      if (e.message.contains('Invalid login credentials') || 
          e.message.contains('invalid_credentials') ||
          e.statusCode == 'invalid_credentials') {
        _setError('Invalid email or password.\n\nIf you just registered, your account may need email verification.\n\nSolution: Check your email for a confirmation link, OR contact support to disable email verification.');
      } else if (e.message.contains('Email not confirmed') ||
                 e.message.contains('email_not_confirmed') ||
                 e.statusCode == 'email_not_confirmed') {
        _setError('Email verification required.\n\nPlease check your email inbox (including spam folder) for the confirmation link and click it.\n\nIf you cannot find the email, you can register again or contact support.');
      } else if (e.message.contains('Too many requests') ||
                 e.statusCode == 'over_email_send_rate_limit') {
        _setError('Too many login attempts. කිහිප විනාඩියකින් නැවත try කරන්න.');
      } else {
        _setError('Login failed: ${e.message}\n\nError code: ${e.statusCode}');
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('❌ Login error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (_supabase == null) return;
      
      _setLoading(true);
      debugPrint('🚪 Signing out user...');
      
      // Before signing out, ensure all data is synced to Supabase
      // Note: This is handled by the cycle provider's sync method
      // We just need to make sure we clear local state properly
      
      await _supabase!.auth.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      debugPrint('✅ User signed out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set password for OAuth users
  Future<bool> setPassword(String password) async {
    try {
      if (_supabase == null || !_isAuthenticated) {
        _setError('User not authenticated');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      final user = _supabase!.auth.currentUser;
      if (user == null) {
        _setError('No user found');
        return false;
      }
      
      // Update user password
      await _supabase!.auth.updateUser(
        UserAttributes(password: password),
      );
      
      return true;
    } catch (e) {
      _setError('Failed to set password: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user has password set
  bool get hasPassword {
    final user = _supabase?.auth.currentUser;
    if (user == null) return false;
    
    // Check if user has password (not OAuth-only)
    return user.appMetadata['provider'] == 'email' || 
           user.appMetadata.containsKey('has_password');
  }

  // Generate a 6-digit OTP code
  String _generateOtpCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = (100000 + (random % 900000)).toString();
    debugPrint('🔵 Generated OTP code: $code');
    return code;
  }

  // Store OTP code in database
  Future<bool> _storeOtpCode(String email, String otpCode) async {
    try {
      if (!await _ensureSupabaseInitialized()) {
        return false;
      }

      // OTP expires in 10 minutes
      final expiresAt = DateTime.now().add(const Duration(minutes: 10)).toIso8601String();

      // Delete any existing OTPs for this email
      await _supabase!.from('password_reset_otp')
          .delete()
          .eq('email', email);

      // Insert new OTP
      await _supabase!.from('password_reset_otp').insert({
        'email': email,
        'otp_code': otpCode,
        'expires_at': expiresAt,
        'used': false,
      });

      debugPrint('✅ OTP code stored in database for $email');
      return true;
    } catch (e) {
      debugPrint('❌ Error storing OTP code: $e');
      return false;
    }
  }

  // Verify OTP code
  Future<bool> verifyOtpCode(String email, String otpCode) async {
    try {
      if (!await _ensureSupabaseInitialized()) {
        _setError('Authentication service not initialized.');
        return false;
      }

      final trimmedEmail = email.trim();
      final trimmedOtp = otpCode.trim();

      // Query for valid OTP
      final response = await _supabase!.from('password_reset_otp')
          .select()
          .eq('email', trimmedEmail)
          .eq('otp_code', trimmedOtp)
          .eq('used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .limit(1)
          .maybeSingle();

      if (response == null) {
        _setError('Invalid or expired verification code. Please request a new code.');
        return false;
      }

      // Mark OTP as used
      await _supabase!.from('password_reset_otp')
          .update({'used': true})
          .eq('id', response['id']);

      debugPrint('✅ OTP code verified successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error verifying OTP code: $e');
      _setError('Failed to verify code. Please try again.');
      return false;
    }
  }

  // Reset password with OTP code
  Future<bool> resetPassword(String email) async {
    try {
      // Ensure Supabase is initialized
      if (!await _ensureSupabaseInitialized()) {
        _setError('Authentication service not initialized. Please check your internet connection and restart the app.');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      final trimmedEmail = email.trim();
      
      // Validate email format first
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedEmail)) {
        _setError('Invalid email address format. Please check your email.');
        return false;
      }
      
      debugPrint('🔵 Attempting to send password reset email with OTP code to: $trimmedEmail');
      
      // Generate 6-digit OTP code
      final otpCode = _generateOtpCode();
      
      // Store OTP in database
      final stored = await _storeOtpCode(trimmedEmail, otpCode);
      if (!stored) {
        _setError('Failed to generate reset code. Please try again.');
        return false;
      }
      
      // Set redirect URL for password reset - this should match the deep link configured in Supabase
      // The redirect URL should be registered in Supabase Dashboard > Authentication > URL Configuration
      final redirectUrl = 'io.supabase.ovumate://reset-password?otp=$otpCode';
      
      // Send password reset email (Supabase will send the email with link)
      // Note: The OTP code needs to be included in the email template
      // Configure the email template in Supabase Dashboard > Authentication > Email Templates
      // Add the OTP code manually or use Edge Functions to send custom emails
      await _supabase!.auth.resetPasswordForEmail(
        trimmedEmail,
        redirectTo: redirectUrl,
      );
      
      // TODO: Send OTP code via email using Supabase Edge Function or custom email service
      // For now, the OTP is stored in database and can be retrieved
      // You can configure Supabase email template to include: "Your reset code is: [OTP_CODE]"
      // Or use Edge Functions to send custom email with OTP
      
      debugPrint('✅ Password reset email sent successfully');
      debugPrint('📧 OTP Code: $otpCode');
      debugPrint('📧 Email will redirect to: $redirectUrl');
      debugPrint('⚠️ IMPORTANT: Make sure this URL is configured in Supabase Dashboard > Authentication > URL Configuration');
      debugPrint('⚠️ IMPORTANT: Update email template in Supabase Dashboard to include OTP code: {{ .OTPCode }} or {{ .Data.otp_code }}');
      
      // Note: Supabase returns success even if email is not configured
      // The email might not actually be sent if:
      // 1. Email confirmation is enabled
      // 2. Email service is not configured
      // 3. Email is going to spam
      
      return true;
    } on AuthException catch (e) {
      // Handle specific auth errors with better messages
      final errorMsg = e.message.toLowerCase();
      
      // Check for rate limit error - multiple patterns
      if (errorMsg.contains('rate_limit') || 
          errorMsg.contains('only request this after') ||
          errorMsg.contains('after') && errorMsg.contains('seconds') ||
          errorMsg.contains('for security purposes')) {
        // Extract wait time from error message
        final waitTimeMatch = RegExp(r'after (\d+) seconds?', caseSensitive: false).firstMatch(e.message);
        if (waitTimeMatch != null) {
          final waitSeconds = int.tryParse(waitTimeMatch.group(1) ?? '') ?? 60;
          final waitMinutes = (waitSeconds / 60).ceil();
          
          if (waitMinutes <= 1) {
            _setError('Please wait $waitSeconds seconds before requesting another password reset. This is for security purposes.');
          } else {
            _setError('Please wait $waitMinutes ${waitMinutes == 1 ? 'minute' : 'minutes'} (${waitSeconds} seconds) before requesting another password reset. This is for security purposes.');
          }
        } else {
          _setError('Too many requests. Please wait a few minutes before trying again. This is for security purposes.');
        }
      } else if (errorMsg.contains('invalid_email')) {
        _setError('Invalid email address. Please check your email and try again.');
      } else if (errorMsg.contains('user_not_found')) {
        _setError('This email is not registered. Please check your email address.');
      } else {
        _setError('Password reset failed: ${e.message}');
      }
      debugPrint('Password reset error: ${e.message}');
      return false;
    } catch (e) {
      // Check for rate limit in generic error too
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('after') && errorString.contains('seconds')) {
        final waitTimeMatch = RegExp(r'after (\d+) seconds?', caseSensitive: false).firstMatch(e.toString());
        if (waitTimeMatch != null) {
          final waitSeconds = int.tryParse(waitTimeMatch.group(1) ?? '') ?? 60;
          final waitMinutes = (waitSeconds / 60).ceil();
          
          if (waitMinutes <= 1) {
            _setError('Please wait $waitSeconds seconds before requesting another password reset.');
          } else {
            _setError('Please wait $waitMinutes ${waitMinutes == 1 ? 'minute' : 'minutes'} before requesting another password reset.');
          }
        } else {
          _setError('Please wait a few minutes before requesting another password reset.');
        }
      } else {
        _setError('Password reset failed: $e');
      }
      debugPrint('Password reset error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resend verification email
  Future<bool> resendVerificationEmail(String email) async {
    try {
      // Ensure Supabase is initialized
      if (!await _ensureSupabaseInitialized()) {
        _setError('Authentication service not initialized. Please check your internet connection and restart the app.');
        return false;
      }
      
      _setLoading(true);
      _clearError();
      
      debugPrint('🔵 Attempting to resend verification email to: $email');
      
      await _supabase!.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
      
      debugPrint('✅ Verification email resent successfully');
      _setError('Verification email sent! Please check your inbox (and spam folder) for the confirmation link.');
      return true;
    } on AuthException catch (e) {
      final errorMsg = e.message.toLowerCase();
      
      // Check for rate limit - multiple patterns
      if (errorMsg.contains('rate limit') || 
          errorMsg.contains('email rate limit exceeded') ||
          errorMsg.contains('too many requests') ||
          (errorMsg.contains('after') && errorMsg.contains('seconds'))) {
        // Extract wait time if available
        final waitTimeMatch = RegExp(r'after (\d+) seconds?', caseSensitive: false).firstMatch(e.message);
        if (waitTimeMatch != null) {
          final waitSeconds = int.tryParse(waitTimeMatch.group(1) ?? '') ?? 60;
          final waitMinutes = (waitSeconds / 60).ceil();
          _setError('Email rate limit exceeded. Please wait $waitMinutes ${waitMinutes == 1 ? 'minute' : 'minutes'} before requesting another verification email. This is a security measure.');
        } else {
          _setError('Email rate limit exceeded. Please wait 5-10 minutes before requesting another verification email. This is a security measure to prevent spam.');
        }
      } else {
        _setError('Failed to resend verification email: ${e.message}');
      }
      debugPrint('Resend verification email error: ${e.message}');
      return false;
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      // Check for rate limit in generic error
      if (errorString.contains('rate limit') || 
          errorString.contains('email rate limit exceeded')) {
        _setError('Email rate limit exceeded. Please wait 5-10 minutes before trying again.');
      } else {
        _setError('Failed to resend verification email: $e');
      }
      debugPrint('Resend verification email error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    try {
      _setLoading(true);
      _clearError();
      
      final response = await _supabase!
          .from('user_profiles')
          .update(updatedProfile.toJson())
          .eq('id', updatedProfile.id)
          .select()
          .single();
      
      _currentUser = UserProfile.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load user profile from database
  Future<void> _loadUserProfile(String userId) async {
    try {
      debugPrint('🔍 Loading user profile for userId: $userId');
      
      // Try to get user profile with better error handling
      final response = await _supabase!
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null) {
        debugPrint('✅ Found user profile in database');
        try {
          _currentUser = UserProfile.fromJson(response);
          debugPrint('✅ User profile loaded successfully');
          debugPrint('   Email: ${_currentUser?.email}');
          debugPrint('   Name: ${_currentUser?.fullName}');
          debugPrint('   Created: ${_currentUser?.createdAt}');
          notifyListeners();
          return;
        } catch (parseError) {
          debugPrint('⚠️ Error parsing user profile: $parseError');
          debugPrint('   Response data: $response');
          // Continue to create new profile if parsing fails
        }
      } else {
        debugPrint('⚠️ User profile not found in database for userId: $userId');
      }
    } catch (e) {
      debugPrint('❌ Error loading user profile: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
      // Don't create new profile on network/connection errors
      if (e.toString().contains('connection') || 
          e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        debugPrint('⚠️ Network error - not creating new profile');
        return;
      }
    }
    
    // Only create default profile if it truly doesn't exist (not due to network error)
    try {
      final user = _supabase!.auth.currentUser;
      if (user != null && _currentUser == null) {
        debugPrint('📝 Creating new user profile for userId: $userId');
        final profile = UserProfile(
          id: user.id,
          email: user.email ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _createUserProfile(profile);
        _currentUser = profile;
        debugPrint('✅ New user profile created');
        notifyListeners();
      }
    } catch (createError) {
      debugPrint('❌ Error creating user profile: $createError');
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(UserProfile profile) async {
    try {
      debugPrint('📝 Creating/updating user profile for userId: ${profile.id}');
      // Use upsert to handle cases where profile might already exist
      final response = await _supabase!
          .from('user_profiles')
          .upsert(profile.toJson())
          .select()
          .single();
      debugPrint('✅ User profile created/updated successfully');
      _currentUser = UserProfile.fromJson(response);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Upsert failed, trying insert: $e');
      // Try insert if upsert fails
      try {
        await _supabase!
            .from('user_profiles')
            .insert(profile.toJson());
        debugPrint('✅ User profile inserted successfully');
        _currentUser = profile;
        notifyListeners();
      } catch (insertError) {
        debugPrint('❌ Error creating user profile: $insertError');
        // Don't throw - profile might already exist
      }
    }
  }
  
  // Force reload user profile (useful for debugging)
  Future<void> forceReloadProfile() async {
    final userId = _supabase?.auth.currentUser?.id;
    if (userId != null) {
      debugPrint('🔄 Force reloading user profile for userId: $userId');
      await _loadUserProfile(userId);
      notifyListeners();
    } else {
      debugPrint('⚠️ Cannot reload: no user ID');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if user has completed onboarding
  bool get hasCompletedOnboarding {
    if (_currentUser == null) return false;
    
    return _currentUser!.averageCycleLength != null &&
           _currentUser!.averagePeriodLength != null &&
           _currentUser!.lastPeriodStart != null;
  }

  // Get user's cycle information
  Map<String, dynamic> get cycleInfo {
    if (_currentUser == null) return {};
    
    return {
      'averageCycleLength': _currentUser!.averageCycleLength,
      'averagePeriodLength': _currentUser!.averagePeriodLength,
      'averageLutealPhase': _currentUser!.averageLutealPhase,
      'lastPeriodStart': _currentUser!.lastPeriodStart,
    };
  }
}

