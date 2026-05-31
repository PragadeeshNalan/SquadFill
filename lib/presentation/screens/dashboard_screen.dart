import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';
import 'package:squadfill/presentation/providers/match_providers.dart';
import 'package:squadfill/presentation/screens/match_detail_screen.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/data/models/user_model.dart';

/// Dashboard Screen providing a premium personalized overview of the player's profile.
class DashboardScreen extends ConsumerWidget {
  /// Default constructor for [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentSquadUserProvider);
    final joinedMatchesAsync = ref.watch(joinedMatchesStreamProvider);
    final activeMatchesAsync = ref.watch(activeMatchesStreamProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Firestore streams auto-refresh, but we add a slight delay for user feedback
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header greeting
                _buildHeader(context, user),
                const SizedBox(height: 24),

                // 2. Reliability Score Widget
                _buildReliabilityCard(context, user),
                const SizedBox(height: 24),

                // 3. AI Behavioral Analytics Insights
                _buildAIInsightsSection(context, user),
                const SizedBox(height: 24),

                // 4. Joined / Upcoming matches feed
                _buildUpcomingGamesFeed(context, joinedMatchesAsync),
                const SizedBox(height: 28),

                // 5. Match recommendations
                _buildRecommendationsSection(context, user, activeMatchesAsync),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a greeting header with user avatar preview.
  Widget _buildHeader(BuildContext context, UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WELCOME BACK,',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: AppTheme.primaryColor.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.name.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 26,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.cardColor,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the Reliability Score Gauge Widget.
  Widget _buildReliabilityCard(BuildContext context, UserModel user) {
    final score = user.reliabilityScore;
    
    // Choose status colors based on reliability score bounds
    Color scoreColor = AppTheme.primaryColor; // Green for reliable
    String scoreStatus = 'EXCELLENT';
    if (score < 60) {
      scoreColor = AppTheme.errorColor; // Red for unreliable
      scoreStatus = 'UNRELIABLE';
    } else if (score < 80) {
      scoreColor = AppTheme.secondaryColor; // Blue for good
      scoreStatus = 'GOOD';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Gauge indicator representation
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.toInt()}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'SCORE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(width: 24),
            
            // Statistics details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      scoreStatus,
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(Icons.check_circle_outline, 'Matches Joined', '${user.matchesJoined}'),
                  const SizedBox(height: 6),
                  _buildStatRow(Icons.cancel_outlined, 'No-Shows Recorded', '${user.noShowCount}', isError: user.noShowCount > 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper row builder for scores card.
  Widget _buildStatRow(IconData icon, String label, String value, {bool isError = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isError ? AppTheme.errorColor : AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isError ? AppTheme.errorColor : Colors.white,
          ),
        ),
      ],
    );
  }

  /// Generates and renders rule-based AI Behavioral Analytics Insight cards.
  Widget _buildAIInsightsSection(BuildContext context, UserModel user) {
    final double score = user.reliabilityScore;
    final int noShows = user.noShowCount;

    List<Map<String, dynamic>> insights = [];

    // AI Insight rules
    if (score < 60) {
      insights.add({
        'title': 'Reliability Warning',
        'message': 'Your score has dropped below 60. You are currently flagged as "Unreliable". Complete matches to build back your reputation!',
        'icon': Icons.warning_amber_rounded,
        'color': AppTheme.errorColor,
      });
    } else if (score >= 95) {
      insights.add({
        'title': 'Elite Player Status',
        'message': 'Outstanding reliability! You are in the top 5% of squad players. Hosts are highly likely to accept you in competitive matches.',
        'icon': Icons.verified_user_rounded,
        'color': AppTheme.primaryColor,
      });
    }

    if (noShows > 1) {
      insights.add({
        'title': 'No-Show Risk Alert',
        'message': 'AI predicts no-show risk. Players with 2+ no-shows may experience limited priority in automatic slot fills.',
        'icon': Icons.insights_rounded,
        'color': AppTheme.errorColor,
      });
    } else {
      insights.add({
        'title': 'Great Commitment',
        'message': 'You have successfully attended your registered games. Keep showing up to unlock higher-tier matches.',
        'icon': Icons.thumb_up_alt_outlined,
        'color': AppTheme.secondaryColor,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'AI BEHAVIORAL ANALYTICS',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            itemBuilder: (context, index) {
              final insight = insights[index];
              return Container(
                width: MediaQuery.of(context).size.width * 0.8,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (insight['color'] as Color).withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (insight['color'] as Color).withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(insight['icon'] as IconData, color: insight['color'] as Color, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            insight['title'] as String,
                            style: TextStyle(
                              color: insight['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              insight['message'] as String,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds a horizontal list feed of user's registered upcoming matches.
  Widget _buildUpcomingGamesFeed(BuildContext context, AsyncValue<List<MatchModel>> joinedMatchesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.secondaryColor),
                const SizedBox(width: 8),
                Text(
                  'YOUR UPCOMING GAMES',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        joinedMatchesAsync.when(
          data: (matches) {
            if (matches.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_rounded, size: 40, color: AppTheme.textSecondaryColor),
                    SizedBox(height: 12),
                    Text(
                      'No upcoming matches joined.',
                      style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Browse open slots to start playing!',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final match = matches[index];
                  final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(match.dateTime);
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MatchDetailScreen(matchId: match.matchId),
                        ),
                      );
                    },
                    child: Container(
                      width: 250,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                match.sport == 'Football' ? Icons.sports_soccer : Icons.sports,
                                color: AppTheme.secondaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  match.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedDate,
                            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  match.venue,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.secondaryColor)),
          error: (err, stack) => const Text('Error loading joined matches'),
        )
      ],
    );
  }

  /// Builds custom match recommendations matching user sport pref & skill.
  Widget _buildRecommendationsSection(
    BuildContext context, 
    UserModel user, 
    AsyncValue<List<MatchModel>> activeMatchesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_outline_rounded, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'RECOMMENDED FOR YOU',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        activeMatchesAsync.when(
          data: (matches) {
            // Recommendation algorithm:
            // Match if same favoriteSport and matches skill level bounds
            final recommended = matches.where((m) {
              return m.organizerId != user.uid && 
                     m.sport.toLowerCase() == user.favoriteSport.toLowerCase();
            }).toList();

            if (recommended.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'No direct match recommendations currently.',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  ),
                ),
              );
            }

            return Column(
              children: recommended.take(3).map((match) {
                final formattedDate = DateFormat('EEE, MMM d • h:mm a').format(match.dateTime);
                final openSlots = match.maxPlayers - match.currentPlayers;
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MatchDetailScreen(matchId: match.matchId),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                            child: Icon(
                              match.sport == 'Football' ? Icons.sports_soccer : Icons.sports,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  match.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$formattedDate • ${match.venue}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$openSlots SLOTS',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                match.skillLevel,
                                style: const TextStyle(color: AppTheme.secondaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          error: (err, stack) => const Text('Error loading recommendations'),
        )
      ],
    );
  }
}
