import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';
import 'package:squadfill/presentation/screens/main_shell.dart';
import 'package:squadfill/presentation/screens/onboarding_screen.dart';
import 'package:squadfill/core/theme/app_theme.dart';

/// Splash Screen displaying the SquadFill branding and checking user session.
class SplashScreen extends ConsumerStatefulWidget {
  /// Default constructor for [SplashScreen].
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set up smooth logo entry animations
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.elasticOut),
    );

    _logoAnimationController.forward();
    _checkSessionState();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  /// Wait for animation, check Riverpod auth stream, and navigate.
  Future<void> _checkSessionState() async {
    // Initial delay for animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authState = ref.read(authStateChangesProvider);

    authState.when(
      data: (user) {
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainShell()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      },
      error: (err, stack) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      },
      loading: () {
        // Fallback: If still loading after another 5 seconds, go to Onboarding
        // this prevents an infinite freeze loop on web if auth is slow.
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && ref.read(authStateChangesProvider).isLoading) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _logoAnimationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_soccer_rounded,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App Name with Sports Gradient Feel
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Squad',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Fill',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'AI-Driven Sports Coordination',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Placeholder Dashboard Screen for Phase 1 compilation and verification.
class PlaceholderDashboardScreen extends StatelessWidget {
  const PlaceholderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SquadFill Dashboard'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_basketball, size: 100, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Successfully Logged In!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Phase 1 Authentication flows are complete. Proceed to Phase 2 to unlock dashboard and match management features.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
