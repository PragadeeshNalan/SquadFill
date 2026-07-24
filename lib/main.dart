import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:squadfill/firebase_options.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/presentation/screens/onboarding_screen.dart';
import 'package:squadfill/presentation/screens/splash_screen.dart';
import 'package:squadfill/presentation/screens/main_shell.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(const ProviderScope(child: SquadFillApp()));
}

class SquadFillApp extends StatelessWidget {
  const SquadFillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SquadFill',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      data: (user) => user != null ? const MainShell() : const OnboardingScreen(),
      loading: () => const SplashScreen(),
      error: (e, s) => const OnboardingScreen(),
    );
  }
}