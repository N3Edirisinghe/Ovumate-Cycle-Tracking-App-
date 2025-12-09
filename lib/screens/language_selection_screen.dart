import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/utils/theme.dart';
import 'package:ovumate/screens/login_screen.dart';
import 'package:ovumate/providers/wellness_provider.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isInitialSelection;
  
  const LanguageSelectionScreen({
    super.key,
    this.isInitialSelection = false,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'en';
  bool _isLoading = false;

  final List<Map<String, String>> _languages = [
    {
      'code': 'en',
      'name': 'English',
      'native': 'English',
      'flag': '🇬🇧',
    },
    {
      'code': 'si',
      'name': 'Sinhala',
      'native': 'සිංහල',
      'flag': '🇱🇰',
    },
    {
      'code': 'ta',
      'name': 'Tamil',
      'native': 'தமிழ்',
      'flag': '🇱🇰',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Hide status bar and navigation bar for immersive fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryPink.withOpacity(0.1),
              AppTheme.secondaryPurple.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              // App Logo
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryPink.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.language,
                  size: 64,
                  color: AppTheme.primaryPink,
                ),
              ),
              const SizedBox(height: 32),
              // Welcome Text
              Text(
                'Choose Your Language',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryPink,
                ),
              ),
              Text(
                'භාෂාව තෝරන්න',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryPurple,
                ),
              ),
              Text(
                'மொழியைத் தேர்ந்தெடுக்கவும்',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryPurple,
                ),
              ),
              const SizedBox(height: 48),
              // Language Options
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    final isSelected = _selectedLanguage == language['code'];
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectLanguage(language['code']!),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isSelected
                                    ? [
                                        AppTheme.primaryPink.withOpacity(0.2),
                                        AppTheme.secondaryPurple.withOpacity(0.2),
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.5),
                                        Colors.white.withOpacity(0.3),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryPink
                                    : Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  language['flag']!,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        language['name']!,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppTheme.primaryPink
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        language['native']!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelected
                                              ? AppTheme.primaryPink.withOpacity(0.8)
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPink.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: AppTheme.primaryPink,
                                      size: 24,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Continue Button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'common.continue'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectLanguage(String code) {
    setState(() {
      _selectedLanguage = code;
    });
  }

  Future<void> _continue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save selected language
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', _selectedLanguage);

      // Update app locale
      await context.setLocale(Locale(_selectedLanguage));

      // Clear articles from memory to prevent type errors
      if (!widget.isInitialSelection && mounted) {
        try {
          final wellnessProvider = Provider.of<WellnessProvider>(context, listen: false);
          wellnessProvider.clearAllArticles();
        } catch (e) {
          debugPrint('Failed to clear articles: $e');
        }
      }
      
      // Navigate based on whether this is initial selection or in-app change
      if (!mounted) return;
      
      if (widget.isInitialSelection) {
        // If initial selection, go to login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      } else {
        // If in-app change, just go back
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving language preference: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}