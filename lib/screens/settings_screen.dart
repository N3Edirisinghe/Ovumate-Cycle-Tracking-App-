import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/utils/responsive_layout.dart';
import 'package:ovumate/screens/language_selection_screen.dart';
import 'package:ovumate/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/theme_provider.dart';
import 'package:ovumate/providers/notification_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Transparent 1x1 PNG image
final Uint8List kTransparentImage = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = '';
  String? _userImagePath;
  bool _isDarkMode = false;
  bool _isNotificationsEnabled = true;
  bool _isPinEnabled = false;
  String _userPin = '';
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();

  String _trKey(String key) {
    try {
      final dynamic value = key.tr();
      if (value is String && value.isNotEmpty && value != key) {
        return value;
      }
      // If translation returns the key itself or is empty, try to get a fallback
      debugPrint('⚠️ Translation issue for key: $key (value: $value)');
      // Return a fallback based on the key
      if (key.contains('help_and_support_subtitle')) {
        return 'FAQ, tutorials, contact support';
      }
      if (key.contains('rate_app_subtitle')) {
        return 'Rate us on the app store';
      }
      if (key.contains('support_and_about')) {
        return 'Support & About';
      }
      // If all else fails, return the key (will be visible but better than empty)
      return value is String ? value : key;
    } catch (e) {
      debugPrint('🔴 Translation error for key: $key => $e');
      // Return fallback text
      if (key.contains('help_and_support_subtitle')) {
        return 'FAQ, tutorials, contact support';
      }
      if (key.contains('rate_app_subtitle')) {
        return 'Rate us on the app store';
      }
      if (key.contains('support_and_about')) {
        return 'Support & About';
      }
      return key;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      debugPrint('🔵 Loading user data...');
      final prefs = await SharedPreferences.getInstance();
      
      // Get each value with extensive logging and type checking
      debugPrint('🔵 Getting user_name...');
      final userName = prefs.getString('user_name');
      debugPrint('🔵 user_name type: ${userName.runtimeType}, value: $userName');
      
      debugPrint('🔵 Getting user_image_path...');
      final userImagePath = prefs.getString('user_image_path');
      debugPrint('🔵 user_image_path type: ${userImagePath.runtimeType}');
      debugPrint('🔵 user_image_path value: ${userImagePath != null ? (userImagePath.length > 100 ? "${userImagePath.substring(0, 100)}..." : userImagePath) : "null"}');
      
      debugPrint('🔵 Getting dark_mode...');
      final darkMode = prefs.getBool('dark_mode');
      debugPrint('🔵 dark_mode: $darkMode');
      
      // Sync with ThemeProvider
      if (mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        if (darkMode != null) {
          await themeProvider.setDarkMode(darkMode);
        }
        
        // Load notification state from NotificationProvider
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        await notificationProvider.loadPendingNotifications();
      }
      
      setState(() {
        _userName = userName ?? '';
        _userImagePath = userImagePath;
        _isDarkMode = darkMode ?? false;
        // Load from NotificationProvider instead of just SharedPreferences
        if (mounted) {
          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
          _isNotificationsEnabled = notificationProvider.notificationsEnabled;
        } else {
        _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        }
        _isPinEnabled = prefs.getBool('pin_enabled') ?? false;
        _userPin = prefs.getString('user_pin') ?? '';
        _nameController.text = _userName;
      });
      debugPrint('🔵 User data loaded successfully');
      debugPrint('🔵 Image path after load: ${_userImagePath != null ? "exists (${_userImagePath!.length} chars)" : "null"}');
    } catch (e, stackTrace) {
      debugPrint('🔴 ERROR in _loadUserData: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      // Set safe defaults
      setState(() {
        _userName = '';
        _userImagePath = null;
        _isDarkMode = false;
        _isNotificationsEnabled = true;
        _isPinEnabled = false;
        _userPin = '';
      });
    }
  }

  Future<void> _saveUserData() async {
    try {
      debugPrint('🔵 Saving user data...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userName);
      if (_userImagePath != null && _userImagePath!.isNotEmpty) {
        debugPrint('🔵 Saving image path: $_userImagePath');
        await prefs.setString('user_image_path', _userImagePath!);
        debugPrint('✅ Image path saved to SharedPreferences');
      } else {
        debugPrint('⚠️ No image path to save');
      }
      await prefs.setBool('dark_mode', _isDarkMode);
      await prefs.setBool('notifications_enabled', _isNotificationsEnabled);
      await prefs.setBool('pin_enabled', _isPinEnabled);
      if (_userPin.isNotEmpty) {
        await prefs.setString('user_pin', _userPin);
      }
      debugPrint('✅ User data saved successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving user data: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      debugPrint('🔵 Starting image picker...');
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('🔵 Image selected: ${image.path}');
        debugPrint('🔵 Image name: ${image.name}');
        
        String imagePath;
        
        // For web, convert to base64 data URL for persistence
        if (kIsWeb) {
          try {
            final bytes = await image.readAsBytes();
            final base64String = base64Encode(bytes);
            imagePath = 'data:image/jpeg;base64,$base64String';
            debugPrint('🔵 Converted image to base64 data URL (length: ${imagePath.length})');
          } catch (e) {
            debugPrint('❌ Error converting image to base64: $e');
            // Fallback to original path
            imagePath = image.path;
          }
        } else {
          // For mobile, use the file path directly
          imagePath = image.path;
          debugPrint('🔵 Using file path for mobile: $imagePath');
        }
        
        debugPrint('🔵 Saving image path: ${imagePath.substring(0, imagePath.length > 100 ? 100 : imagePath.length)}...');
        
        setState(() {
          _userImagePath = imagePath;
        });
        
        await _saveUserData();
        debugPrint('✅ Image saved successfully');
        
        // Verify it was saved
        final prefs = await SharedPreferences.getInstance();
        final savedPath = prefs.getString('user_image_path');
        debugPrint('🔵 Verified saved image path exists: ${savedPath != null && savedPath.isNotEmpty}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('⚠️ No image selected');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error picking image: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  ImageProvider _getImageProvider(String imagePath) {
    // Check if it's a base64 data URL (web)
    if (imagePath.startsWith('data:image')) {
      try {
        final base64String = imagePath.split(',')[1];
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('❌ Error decoding base64 image: $e');
        // Fallback to network image
        return NetworkImage(imagePath);
      }
    }
    // Check if it's a file path (mobile)
    else if (!kIsWeb) {
      try {
        final file = File(imagePath);
        if (file.existsSync()) {
          return FileImage(file);
        } else {
          debugPrint('⚠️ File does not exist: $imagePath');
          // Return a transparent image provider as fallback
          return MemoryImage(kTransparentImage);
        }
      } catch (e) {
        debugPrint('❌ Error loading file image: $e');
        // Fallback to network image
        return NetworkImage(imagePath);
      }
    }
    // Fallback to network image (for URLs)
    else {
      return NetworkImage(imagePath);
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_trKey('settings.edit_name.title')),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: _trKey('settings.edit_name.label'),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = _nameController.text;
              });
              _saveUserData();
              Navigator.pop(context);
            },
            child: Text(_trKey('common.save')),
          ),
        ],
      ),
    );
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: AppTheme.primaryPink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_trKey('settings.security_settings.title')),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(_trKey('settings.security_settings.enable_pin')),
              subtitle: Text(_trKey('settings.security_settings.enable_pin_subtitle')),
              value: _isPinEnabled,
              activeColor: AppTheme.primaryPink,
              onChanged: (value) {
                if (value && _userPin.isEmpty) {
                  // Show PIN setup dialog
                  Navigator.pop(context);
                  _showSetupPinDialog();
                } else {
                  setState(() {
                    _isPinEnabled = value;
                  });
                  _saveUserData();
                  Navigator.pop(context);
                }
              },
            ),
            if (_isPinEnabled) ...[
              Divider(),
              ListTile(
                leading: Icon(Icons.edit, color: AppTheme.primaryPink),
                title: Text(_trKey('settings.security_settings.change_pin')),
                onTap: () {
                  Navigator.pop(context);
                  _showChangePinDialog();
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('common.close')),
          ),
        ],
      ),
    );
  }

  void _showSetupPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_trKey('settings.security_settings.setup_pin')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_trKey('settings.security_settings.create_pin')),
            SizedBox(height: 16),
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: _trKey('settings.security_settings.enter_pin'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.length == 4) {
                setState(() {
                  _userPin = _pinController.text;
                  _isPinEnabled = true;
                });
                _saveUserData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_trKey('settings.security_settings.pin_setup_success')),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_trKey('settings.security_settings.pin_must_be_4')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(_trKey('common.save')),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_trKey('settings.security_settings.change_pin')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_trKey('settings.security_settings.create_pin')),
            SizedBox(height: 16),
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.length == 4) {
                setState(() {
                  _userPin = _pinController.text;
                });
                _saveUserData();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_trKey('settings.security_settings.pin_changed_success')),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_trKey('settings.security_settings.pin_must_be_4')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(_trKey('common.save')),
          ),
        ],
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.help_outline, color: AppTheme.primaryPink),
            SizedBox(width: 12),
            Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem(
                icon: Icons.article_outlined,
                title: 'User Guide',
                description: 'Learn how to use the app',
                onTap: () {
                  Navigator.pop(context);
                  _showUserGuide();
                },
              ),
              Divider(),
              _buildHelpItem(
                icon: Icons.question_answer,
                title: 'FAQs',
                description: 'Frequently asked questions',
                onTap: () {
                  Navigator.pop(context);
                  _showFAQs();
                },
              ),
              Divider(),
              _buildHelpItem(
                icon: Icons.email_outlined,
                title: 'Contact Support',
                description: 'support@ovumate.com',
                onTap: () {
                  Navigator.pop(context);
                  _showContactSupport();
                },
              ),
              Divider(),
              _buildHelpItem(
                icon: Icons.bug_report_outlined,
                title: 'Report a Bug',
                description: 'Help us improve the app',
                onTap: () {
                  Navigator.pop(context);
                  _showBugReport();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('common.close')),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryPink),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(description),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _showFeedback() {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.feedback_outlined, color: AppTheme.primaryPink),
            SizedBox(width: 12),
            Text('Send Feedback'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('We\'d love to hear your thoughts!'),
            SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: InputDecoration(
                labelText: 'Your Feedback',
                border: OutlineInputBorder(),
                hintText: 'Tell us what you think...',
              ),
              maxLines: 5,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              feedbackController.dispose();
              Navigator.pop(context);
            },
            child: Text(_trKey('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (feedbackController.text.isNotEmpty) {
                // TODO: Send feedback to backend
                feedbackController.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Thank you for your feedback!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.article_outlined, color: AppTheme.primaryPink),
            SizedBox(width: 12),
            Text('User Guide'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideSection(
                '📅 Cycle Tracking',
                'Track your menstrual cycle, log symptoms, moods, and activities. View your calendar and predictions.',
              ),
              Divider(),
              _buildGuideSection(
                '💧 Sleep & Water',
                'Monitor your sleep quality and water intake. Set daily goals and track your progress.',
              ),
              Divider(),
              _buildGuideSection(
                '🤖 AI Health Assistant',
                'Ask health-related questions and get personalized guidance in your preferred language.',
              ),
              Divider(),
              _buildGuideSection(
                '⚙️ Settings',
                'Customize your experience, enable security features, and manage your account.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('common.close')),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppTheme.primaryPink,
            ),
          ),
          SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showFAQs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.question_answer, color: AppTheme.primaryPink),
            SizedBox(width: 12),
            Text('FAQs'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem(
                'How accurate are the predictions?',
                'Predictions become more accurate as you log more cycles. We use advanced algorithms based on your personal data.',
              ),
              Divider(),
              _buildFAQItem(
                'Is my data secure?',
                'Yes! All your data is encrypted and stored securely. We never share your personal information.',
              ),
              Divider(),
              _buildFAQItem(
                'Can I use the app offline?',
                'Yes, most features work offline. The AI assistant requires an internet connection.',
              ),
              Divider(),
              _buildFAQItem(
                'How do I backup my data?',
                'Your data is automatically synced to the cloud when you\'re connected to the internet.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('common.close')),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.primaryPink,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'A: $answer',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email_outlined, color: AppTheme.primaryPink),
            SizedBox(width: 12),
            Text('Contact Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need help? We\'re here for you!'),
            SizedBox(height: 20),
            _buildContactItem(Icons.email, 'Email', 'support@ovumate.com'),
            SizedBox(height: 12),
            _buildContactItem(Icons.phone, 'Phone', '+1 (800) 123-4567'),
            SizedBox(height: 12),
            _buildContactItem(Icons.schedule, 'Hours', 'Mon-Fri 9AM-6PM EST'),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryPink, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We typically respond within 24 hours',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryPink, size: 20),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  void _showBugReport() {
    final bugController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.bug_report_outlined, color: AppTheme.primaryPink),
            SizedBox(width: 12),
            Text('Report a Bug'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Help us improve by reporting any issues you encounter.'),
            SizedBox(height: 16),
            TextField(
              controller: bugController,
              decoration: InputDecoration(
                labelText: 'Describe the bug',
                border: OutlineInputBorder(),
                hintText: 'What happened? When did it occur?',
              ),
              maxLines: 5,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              bugController.dispose();
              Navigator.pop(context);
            },
            child: Text(_trKey('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (bugController.text.isNotEmpty) {
                // TODO: Send bug report to backend
                bugController.dispose();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bug report submitted. Thank you!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp() async {
    // Show rating options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 12),
            Text(_trKey('settings.rate.title')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_trKey('settings.rate.message')),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 32,
                );
              }),
            ),
            SizedBox(height: 20),
            Text(
              _trKey('settings.rate.feedback_help'),
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_trKey('settings.rate.maybe_later')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Try to open app store
              try {
                final Uri url;
                if (Platform.isAndroid) {
                  // Replace with your actual package name
                  url = Uri.parse('https://play.google.com/store/apps/details?id=com.ovumate.app');
                } else if (Platform.isIOS) {
                  // Replace with your actual app ID
                  url = Uri.parse('https://apps.apple.com/app/idYOUR_APP_ID');
                } else {
                  // For Windows or other platforms, show a thank you message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_trKey('settings.rate.thank_you')),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  return;
                }
                
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_trKey('settings.rate.error')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thank you for your support!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: Text(_trKey('settings.rate.rate_now')),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text(_trKey('settings.sign_out_dialog.title')),
          ],
        ),
        content: Text(_trKey('settings.sign_out_dialog.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_trKey('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              // Clear user session data (keep user data for next login)
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', false);
              
              // Close dialog first
              Navigator.pop(dialogContext);
              
              // Show success message using the widget's context
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_trKey('settings.sign_out_dialog.success')),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Navigate to login screen after a short delay
                await Future.delayed(Duration(seconds: 2));
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false, // Remove all previous routes
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_trKey('settings.sign_out')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 Building SettingsScreen with locale: ${context.locale}');
    
    return Scaffold(
      key: ValueKey(context.locale.toString()), // Force rebuild when language changes
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
          child: Column(
            children: [
              _buildProfessionalAppBar(context),
              Expanded(
                child: Builder(
                  builder: (context) {
                    try {
                      debugPrint('🔵 Rendering settings body...');
                      return _buildSettingsBody(context);
                    } catch (e, stackTrace) {
                      debugPrint('🔴 ERROR rendering settings body: $e');
                      debugPrint('🔴 Stack trace: $stackTrace');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Error loading settings', style: TextStyle(fontSize: 18)),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('$e', textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPink,
            AppTheme.secondaryPurple,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _trKey('settings.title'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsBody(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Professional Profile Card
          _buildProfileCard(context, isMobile),
          const SizedBox(height: 24),

          // Settings sections
          _buildSettingsSection(
            context: context,
            title: _trKey('settings.account_settings'),
            children: [
                _buildSettingsTile(
                  context: context,
                  icon: Icons.security,
                  title: _trKey('settings.security'),
                  subtitle: _trKey('settings.security_subtitle'),
                  onTap: _showSecuritySettings,
                ),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) {
                    return _buildSettingsTile(
                  context: context,
                  icon: Icons.notifications,
                  title: _trKey('settings.notifications'),
                  subtitle: _trKey('settings.notifications_subtitle'),
                  trailing: Switch(
                        value: notificationProvider.notificationsEnabled,
                        onChanged: (value) async {
                          await notificationProvider.toggleNotifications();
                      setState(() {
                            _isNotificationsEnabled = notificationProvider.notificationsEnabled;
                      });
                      _saveUserData();
                          
                          // Show feedback message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  notificationProvider.notificationsEnabled
                                      ? 'Notifications enabled'
                                      : 'Notifications disabled',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: notificationProvider.notificationsEnabled
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            );
                          }
                    },
                    activeColor: AppTheme.primaryPink,
                  ),
                    );
                  },
                ),
              _buildSettingsTile(
                context: context,
                icon: Icons.language,
                title: _trKey('settings.language'),
                subtitle: _trKey('settings.language_subtitle'),
                isLast: true,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LanguageSelectionScreen(
                        isInitialSelection: false,
                      ),
                    ),
                  );
                  if (mounted) {
                    await Future.delayed(const Duration(milliseconds: 100));
                    setState(() {
                      _loadUserData();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context: context,
            title: _trKey('settings.app_preferences'),
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.dark_mode,
                title: _trKey('settings.dark_mode'),
                subtitle: _trKey('settings.dark_mode_subtitle'),
                isLast: true,
                trailing: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) async {
                        await themeProvider.setDarkMode(value);
                        setState(() {
                          _isDarkMode = value;
                        });
                        _saveUserData();
                      },
                      activeColor: AppTheme.primaryPink,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context: context,
            title: _trKey('settings.support_and_about'),
            children: [
              _buildSettingsTile(
                context: context,
                icon: Icons.help_outline,
                title: _trKey('settings.help_and_support'),
                subtitle: _trKey('settings.help_and_support_subtitle'),
                onTap: _showHelpSupport,
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.feedback_outlined,
                title: _trKey('settings.feedback'),
                subtitle: _trKey('settings.feedback_subtitle'),
                onTap: _showFeedback,
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.star_outline,
                title: _trKey('settings.rate_app'),
                subtitle: _trKey('settings.rate_app_subtitle'),
                isLast: true,
                onTap: _rateApp,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Sign out button
          _buildSignOutButton(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPink.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPink.withOpacity(0.2),
                        AppTheme.secondaryPurple.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.primaryPink,
                      width: 4,
                    ),
                    image: _userImagePath != null && _userImagePath!.isNotEmpty
                        ? DecorationImage(
                            image: _getImageProvider(_userImagePath!),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              debugPrint('❌ Error loading image: $exception');
                              debugPrint('❌ Image path: ${_userImagePath!.substring(0, _userImagePath!.length > 100 ? 100 : _userImagePath!.length)}...');
                            },
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryPink.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _userImagePath == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: AppTheme.primaryPink.withOpacity(0.5),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryPink, AppTheme.secondaryPurple],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPink.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _showEditNameDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryPink.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _userName.isEmpty
                          ? _trKey('settings.tap_to_add_name')
                          : _userName,
                      style: const TextStyle(
                        color: AppTheme.primaryPink,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 18,
                    color: AppTheme.primaryPink,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _showSignOutConfirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: 12),
            Text(
              _trKey('settings.sign_out'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryPink.withOpacity(0.15),
                        AppTheme.secondaryPurple.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryPink,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 24,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }
}