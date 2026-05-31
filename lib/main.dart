import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:squadfill/firebase_options.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/presentation/screens/splash_screen.dart';

/// Entry point of the SquadFill application.
void main() async {
  // Ensure widget bindings are initialized before async setup
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase services using standard resolved options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Catch initialization errors if mock keys are present or offline,
    // logging the warning but keeping the UI shell operational.
    debugPrint("Firebase initialization failed: $e");
  }

  // Wrap root widget in Riverpod's ProviderScope for state management
  runApp(
    const ProviderScope(
      child: SquadFillApp(),
    ),
  );
}

/// Root widget configuring material design attributes.
class SquadFillApp extends StatelessWidget {
  /// Default constructor for [SquadFillApp].
  const SquadFillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SquadFill',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
