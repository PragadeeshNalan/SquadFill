import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squadfill/presentation/screens/dashboard_screen.dart';
import 'package:squadfill/presentation/screens/match_list_screen.dart';
import 'package:squadfill/presentation/screens/create_match_screen.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';

/// Main Shell Container orchestrating top-level application navigation.
class MainShell extends ConsumerStatefulWidget {
  /// Default constructor for [MainShell].
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  // Active screens list
  final List<Widget> _screens = [
    const DashboardScreen(),
    const MatchListScreen(),
    const FakeMapsScreen(),
    const FakeProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // Floating button to Host a Match
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreateMatchScreen()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.cardColor,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.space_dashboard_rounded, 'Dashboard', 0),
            _buildNavItem(Icons.sports_soccer_rounded, 'Matches', 1),
            const SizedBox(width: 48), // Spacer space for floating action button notch
            _buildNavItem(Icons.map_outlined, 'Maps', 2),
            _buildNavItem(Icons.person_outline_rounded, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  /// Builds a single BottomAppBar navigation item.
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor;

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
            });
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dynamic premium placeholder for the Maps Screen.
class FakeMapsScreen extends StatelessWidget {
  const FakeMapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.map_rounded, size: 64, color: AppTheme.secondaryColor),
            ),
            const SizedBox(height: 24),
            Text('Google Maps Feed', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Interactive geographic match discovery and distance limits sliders are currently loading. Ready to unlock in Phase 3!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic premium placeholder for the Profile + Analytics Screen.
class FakeProfileScreen extends StatelessWidget {
  const FakeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer(
        builder: (context, ref, child) {
          final user = ref.watch(currentSquadUserProvider);
          if (user == null) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          final score = user.reliabilityScore;
          Color scoreColor = AppTheme.primaryColor;
          if (score < 60) {
            scoreColor = AppTheme.errorColor;
          } else if (score < 80) {
            scoreColor = AppTheme.secondaryColor;
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
                  Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 32),
                  
                  // Score gauge indicator
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: scoreColor, width: 3),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${score.toInt()}',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: scoreColor),
                          ),
                          const Text(
                            'RELIABILITY',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Stats Block preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProfileStat('Joined', '${user.matchesJoined}'),
                        _buildProfileStat('No-Shows', '${user.noShowCount}'),
                        _buildProfileStat('Skill', user.skillLevel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sign Out Session'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
