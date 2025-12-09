import 'package:flutter/material.dart';
import 'package:ovumate/utils/constants.dart';

class OnboardingStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const OnboardingStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Constants.defaultPadding),
      child: Column(
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(Constants.textPrimaryColor),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: Color(Constants.textSecondaryColor),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}


