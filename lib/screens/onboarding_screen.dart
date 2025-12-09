import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ovumate/providers/auth_provider.dart';
import 'package:ovumate/screens/main_navigation.dart';
import 'package:ovumate/utils/constants.dart';
import 'package:ovumate/widgets/onboarding_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  
  // Cycle information
  int _averageCycleLength = Constants.defaultCycleLength;
  int _averagePeriodLength = Constants.defaultPeriodLength;
  DateTime? _lastPeriodStart;
  
  // Wellness goals
  final List<String> _selectedWellnessGoals = [];
  final List<String> _selectedHealthConditions = [];
  
  // Available options
  final List<String> _wellnessGoalOptions = [
    'Better sleep',
    'Stress management',
    'Healthy eating',
    'Regular exercise',
    'Mental health',
    'Fertility awareness',
    'Hormone balance',
    'Pain management',
  ];
  
  final List<String> _healthConditionOptions = [
    'PCOS',
    'Endometriosis',
    'Fibroids',
    'Irregular cycles',
    'Heavy periods',
    'PMS',
    'None',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleWellnessGoal(String goal) {
    setState(() {
      if (_selectedWellnessGoals.contains(goal)) {
        _selectedWellnessGoals.remove(goal);
      } else {
        _selectedWellnessGoals.add(goal);
      }
    });
  }

  void _toggleHealthCondition(String condition) {
    setState(() {
      if (_selectedHealthConditions.contains(condition)) {
        _selectedHealthConditions.remove(condition);
      } else {
        _selectedHealthConditions.add(condition);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Create account if not already signed in
      if (!authProvider.isAuthenticated) {
        final success = await authProvider.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );
        
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authProvider.errorMessage ?? 'Sign up failed')),
          );
          return;
        }
      }
      
      // Update profile with cycle information
      if (authProvider.currentUser != null) {
        final updatedProfile = authProvider.currentUser!.copyWith(
          dateOfBirth: _parseDateOfBirth(),
          averageCycleLength: _averageCycleLength,
          averagePeriodLength: _averagePeriodLength,
          lastPeriodStart: _lastPeriodStart,
          wellnessGoals: _selectedWellnessGoals,
          healthConditions: _selectedHealthConditions,
        );
        
        await authProvider.updateProfile(updatedProfile);
      }
      
      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  DateTime? _parseDateOfBirth() {
    if (_dateOfBirthController.text.isEmpty) return null;
    try {
      return DateTime.parse(_dateOfBirthController.text);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Constants.backgroundColor),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _currentStep > 0 ? _previousStep : null,
                    icon: const Icon(Icons.arrow_back),
                    color: _currentStep > 0 
                        ? const Color(Constants.primaryColor) 
                        : Colors.grey,
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / 5,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(Constants.primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Constants.defaultPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _currentStep
                          ? const Color(Constants.primaryColor)
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Step 1: Welcome
                  OnboardingStep(
                    title: 'Welcome to OvuMate!',
                    subtitle: 'Your personal cycle companion for better health and wellness.',
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 80,
                          color: Color(Constants.primaryColor),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Let\'s get started by setting up your profile and preferences. This will help us provide you with accurate predictions and personalized insights.',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Step 2: Account creation
                  OnboardingStep(
                    title: 'Create Your Account',
                    subtitle: 'Set up your secure account to start tracking.',
                    child: Column(
                      children: [
                        TextField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            hintText: 'Enter your first name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            hintText: 'Enter your last name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email address',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Create a secure password',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _dateOfBirthController,
                          decoration: const InputDecoration(
                            labelText: 'Date of Birth',
                            hintText: 'YYYY-MM-DD',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
                              firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              _dateOfBirthController.text = date.toIso8601String().split('T')[0];
                            }
                          },
                          readOnly: true,
                        ),
                      ],
                    ),
                  ),
                  
                  // Step 3: Cycle information
                  OnboardingStep(
                    title: 'Cycle Information',
                    subtitle: 'Help us understand your cycle better.',
                    child: Column(
                      children: [
                        const Text(
                          'Average Cycle Length',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Slider(
                          value: _averageCycleLength.toDouble(),
                          min: 21,
                          max: 35,
                          divisions: 14,
                          label: '$_averageCycleLength days',
                          onChanged: (value) {
                            setState(() {
                              _averageCycleLength = value.round();
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Average Period Length',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        Slider(
                          value: _averagePeriodLength.toDouble(),
                          min: 3,
                          max: 7,
                          divisions: 4,
                          label: '$_averagePeriodLength days',
                          onChanged: (value) {
                            setState(() {
                              _averagePeriodLength = value.round();
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        const Text(
                          'Last Period Start',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 90)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _lastPeriodStart = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_lastPeriodStart != null 
                              ? '${_lastPeriodStart!.day}/${_lastPeriodStart!.month}/${_lastPeriodStart!.year}'
                              : 'Select Date'),
                        ),
                      ],
                    ),
                  ),
                  
                  // Step 4: Wellness goals
                  OnboardingStep(
                    title: 'Wellness Goals',
                    subtitle: 'What would you like to focus on?',
                    child: Column(
                      children: [
                        const Text(
                          'Select your wellness goals (choose all that apply):',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _wellnessGoalOptions.map((goal) {
                            final isSelected = _selectedWellnessGoals.contains(goal);
                            return FilterChip(
                              label: Text(goal),
                              selected: isSelected,
                              onSelected: (_) => _toggleWellnessGoal(goal),
                              selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                              checkmarkColor: const Color(Constants.primaryColor),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Step 5: Health conditions
                  OnboardingStep(
                    title: 'Health Information',
                    subtitle: 'Help us provide personalized insights.',
                    child: Column(
                      children: [
                        const Text(
                          'Do you have any of these health conditions? (choose all that apply):',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _healthConditionOptions.map((condition) {
                            final isSelected = _selectedHealthConditions.contains(condition);
                            return FilterChip(
                              label: Text(condition),
                              selected: isSelected,
                              onSelected: (_) => _toggleHealthCondition(condition),
                              selectedColor: const Color(Constants.primaryColor).withOpacity(0.2),
                              checkmarkColor: const Color(Constants.primaryColor),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(Constants.defaultPadding),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep == 4 ? _completeOnboarding : _nextStep,
                      child: Text(_currentStep == 4 ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


