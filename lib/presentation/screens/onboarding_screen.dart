import 'package:flutter/material.dart';
import 'package:squadfill/presentation/screens/login_screen.dart';
import 'package:squadfill/presentation/screens/register_screen.dart';
import 'package:squadfill/core/theme/app_theme.dart';

/// Onboarding screen introducing SquadFill key value propositions.
class OnboardingScreen extends StatefulWidget {
  /// Default constructor for [OnboardingScreen].
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Onboarding item details
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'No More Last-Minute Cancellations',
      'description': 'SquadFill solves sports match cancellations caused by player no-shows. Easily find fill-in players for your games.',
      'icon': Icons.sports_soccer_rounded,
      'accentColor': AppTheme.primaryColor,
    },
    {
      'title': 'Track Reliability Scores',
      'description': 'Earn points by showing up on time. Build your reputation and join premium competitive local matchups.',
      'icon': Icons.trending_up_rounded,
      'accentColor': AppTheme.secondaryColor,
    },
    {
      'title': 'Smart AI Match Analytics',
      'description': 'View participation insights, predict cancellation risks, and get personalized local match recommendations.',
      'icon': Icons.insights_rounded,
      'accentColor': AppTheme.primaryColor,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
                  ),
                ),
              ),
            ),
            
            // Onboarding Slides (PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Slide Icon Container
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: (data['accentColor'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (data['accentColor'] as Color).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            data['icon'] as IconData,
                            size: 100,
                            color: data['accentColor'] as Color,
                          ),
                        ),
                        const SizedBox(height: 48),
                        
                        // Slide Title
                        Text(
                          data['title'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Slide Description
                        Text(
                          data['description'] as String,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Dot Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? _onboardingData[index]['accentColor'] as Color
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _onboardingData.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _onboardingData.length - 1 
                          ? 'Create Account' 
                          : 'Next',
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
