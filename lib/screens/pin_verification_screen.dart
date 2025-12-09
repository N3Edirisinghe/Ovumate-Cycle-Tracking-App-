import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/screens/main_navigation.dart';
import 'package:easy_localization/easy_localization.dart';

class PinVerificationScreen extends StatefulWidget {
  final VoidCallback? onVerified;
  
  const PinVerificationScreen({super.key, this.onVerified});

  @override
  State<PinVerificationScreen> createState() => _PinVerificationScreenState();
}

class _PinVerificationScreenState extends State<PinVerificationScreen> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  String _enteredPin = '';
  bool _isError = false;
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    // Focus on first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      value = value.substring(0, 1);
    }
    
    setState(() {
      _pinControllers[index].text = value;
      _isError = false;
    });

    if (value.isNotEmpty && index < 3) {
      // Move to next field
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move to previous field on backspace
      _focusNodes[index - 1].requestFocus();
    }

    // Don't auto-check, wait for OK button
  }

  void _onOkPressed() {
    final pin = _pinControllers.map((c) => c.text).join();
    
    if (pin.length != 4) {
      // Show error if PIN is not complete
      setState(() {
        _isError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a 4-digit PIN'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    _checkPin();
  }

  Future<void> _checkPin() async {
    if (!mounted) return;
    
    final pin = _pinControllers.map((c) => c.text).join();
    
    if (pin.length != 4) {
      debugPrint('⚠️ PIN length is not 4: ${pin.length}');
      return;
    }
    
    debugPrint('🔵 Checking PIN: ${pin.replaceAll(RegExp(r'.'), '*')}');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('user_pin') ?? '';
      final isPinEnabled = prefs.getBool('pin_enabled') ?? false;

      debugPrint('🔵 Saved PIN exists: ${savedPin.isNotEmpty}');
      debugPrint('🔵 PIN enabled: $isPinEnabled');
      debugPrint('🔵 Saved PIN length: ${savedPin.length}');

      if (!mounted) return;

      if (!isPinEnabled || savedPin.isEmpty) {
        // PIN not enabled, allow access
        debugPrint('✅ PIN not enabled or empty, allowing access');
        _navigateToApp();
        return;
      }

      // Compare PINs (trim whitespace just in case)
      final enteredPin = pin.trim();
      final storedPin = savedPin.trim();
      
      debugPrint('🔵 Comparing: entered="${enteredPin.replaceAll(RegExp(r'.'), '*')}" vs stored="${storedPin.replaceAll(RegExp(r'.'), '*')}"');

      if (enteredPin == storedPin) {
        // Correct PIN
        debugPrint('✅ PIN is correct! Navigating to app...');
        
        if (!mounted) return;
        
        setState(() {
          _isError = false;
          _attempts = 0;
        });
        
        // Navigate immediately
        _navigateToApp();
      } else {
        // Wrong PIN
        debugPrint('❌ PIN is incorrect');
        
        if (!mounted) return;
        
        setState(() {
          _isError = true;
          _attempts++;
        });
        
        debugPrint('🔵 Attempts: $_attempts/$_maxAttempts');
        
        // Clear PIN fields
        for (var controller in _pinControllers) {
          controller.clear();
        }
        
        if (!mounted) return;
        _focusNodes[0].requestFocus();

        if (_attempts >= _maxAttempts) {
          _showMaxAttemptsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking PIN: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying PIN: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToApp() {
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, cannot navigate');
      return;
    }
    
    debugPrint('🔵 Navigating to app after PIN verification...');
    
    // Use WidgetsBinding to ensure navigation happens after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        debugPrint('⚠️ Widget not mounted in postFrameCallback');
        return;
      }
      
      // Use the onVerified callback if available (preferred method)
      if (widget.onVerified != null) {
        debugPrint('🔵 Using onVerified callback');
        try {
          // Execute callback immediately
          widget.onVerified!();
          debugPrint('✅ onVerified callback executed successfully');
          return;
        } catch (e, stackTrace) {
          debugPrint('❌ Error in onVerified callback: $e');
          debugPrint('❌ Stack trace: $stackTrace');
          // Fallback to direct navigation
        }
      }
      
      // Fallback: Navigate directly
      debugPrint('🔵 Using direct navigation (no callback provided)');
      _navigateDirectly();
    });
  }

  void _navigateDirectly() {
    if (!mounted) {
      debugPrint('⚠️ Widget not mounted, cannot navigate directly');
      return;
    }
    
    debugPrint('🔵 Starting direct navigation...');
    
    // Navigate immediately using root navigator to ensure it works
    try {
      // First try: root navigator (most reliable)
      debugPrint('🔵 Attempting root navigator pushAndRemoveUntil...');
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      rootNavigator.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) {
            debugPrint('🔵 Building MainNavigation widget...');
            return const MainNavigation();
          },
        ),
        (route) => false, // Remove all previous routes
      );
      debugPrint('✅ Navigation successful with root navigator');
    } catch (e) {
      debugPrint('❌ Error in root navigator: $e');
      
      // Second try: regular navigator pushAndRemoveUntil
      try {
        if (mounted) {
          debugPrint('🔵 Attempting regular navigator pushAndRemoveUntil...');
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
            (route) => false,
          );
          debugPrint('✅ Navigation successful with regular navigator');
        }
      } catch (e2) {
        debugPrint('❌ Error in regular navigator: $e2');
        
        // Third try: pushReplacement
        try {
          if (mounted) {
            debugPrint('🔵 Attempting pushReplacement...');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainNavigation(),
              ),
            );
            debugPrint('✅ Navigation successful with pushReplacement');
          }
        } catch (e3) {
          debugPrint('❌ PushReplacement error: $e3');
          
          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigation error. Please restart the app.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Too Many Attempts'),
          ],
        ),
        content: const Text(
          'You have exceeded the maximum number of PIN attempts. Please restart the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Exit app or navigate to login
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResetPinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: AppTheme.primaryPink),
            const SizedBox(width: 12),
            const Text(
              'Reset PIN',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to reset your PIN? You will need to set up a new PIN in Settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetPin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Disable PIN and clear saved PIN
      await prefs.setBool('pin_enabled', false);
      await prefs.remove('user_pin');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PIN has been reset. You can set a new PIN in Settings.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate to main app since PIN is disabled
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Use the onVerified callback if available, otherwise navigate directly
      if (widget.onVerified != null) {
        widget.onVerified!();
      } else {
        // Navigate to main navigation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) {
              // Import MainNavigation at the top
              return const MainNavigation();
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('Error resetting PIN: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting PIN: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundDark,
              AppTheme.secondaryPurple.withOpacity(0.3),
              AppTheme.primaryPink.withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPink.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: AppTheme.primaryPink,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Enter PIN',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your 4-digit PIN to continue',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 48),
                
                // PIN input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isError
                              ? Colors.red
                              : (_pinControllers[index].text.isNotEmpty
                                  ? AppTheme.primaryPink
                                  : Colors.grey.shade300),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _pinControllers[index].text.isNotEmpty
                                ? AppTheme.primaryPink.withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _pinControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        obscureText: true,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryDark,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => _onPinChanged(index, value),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                
                // Error message
                if (_isError)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Incorrect PIN',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                
                // OK Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPink,
                        AppTheme.secondaryPurple,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onOkPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reset PIN button
                TextButton(
                  onPressed: _showResetPinDialog,
                  child: Text(
                    'Forgot PIN? Reset',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
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

