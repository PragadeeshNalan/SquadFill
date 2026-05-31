import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';
import 'package:squadfill/presentation/providers/match_providers.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/core/constants/app_constants.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/data/models/participant_model.dart';
import 'package:squadfill/data/models/user_model.dart';

/// Live Match Detail Lobby synced in real-time with Firestore.
class MatchDetailScreen extends ConsumerWidget {
  /// Unique database ID of the match to display.
  final String matchId;

  /// Default constructor for [MatchDetailScreen].
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentSquadUserProvider)?.uid;
    final matchAsync = ref.watch(matchDetailStreamProvider(matchId));
    final participantsAsync = ref.watch(matchParticipantsStreamProvider(matchId));
    final controllerState = ref.watch(matchControllerProvider);
    final isActionLoading = controllerState is AsyncLoading;

    // Listen to handle joining/leaving transaction failures
    ref.listen<AsyncValue<void>>(matchControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Match Lobby'),
      ),
      body: matchAsync.when(
        data: (match) {
          if (match == null) {
            return const Center(child: Text('Match not found or deleted.'));
          }

          final organizerAsync = ref.watch(userProfileProvider(match.organizerId));

          return Column(
            children: [
              // Scrollable Details body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Sport Icon & Title Row
                      _buildSportTitleRow(match),
                      const SizedBox(height: 16),

                      // 2. Info Grid (Date, Venue, Coordinates)
                      _buildInfoGrid(context, match),
                      const SizedBox(height: 24),

                      // 3. Organizer Bio Block
                      _buildOrganizerCard(context, organizerAsync),
                      const SizedBox(height: 24),

                      // 4. Team Balancing Widget Engine
                      participantsAsync.when(
                        data: (parts) => _buildTeamBalancingWidget(context, match, parts),
                        loading: () => const Center(child: LinearProgressIndicator(color: AppTheme.primaryColor)),
                        error: (err, stack) => const Text('Error loading skill stats'),
                      ),
                      const SizedBox(height: 24),

                      // 5. Participants Feed Section
                      _buildParticipantsFeed(context, participantsAsync),
                    ],
                  ),
                ),
              ),

              // 6. Sticky Action Footer (Join / Leave / Cancel button)
              participantsAsync.when(
                data: (parts) => _buildActionFooter(context, ref, match, parts, currentUserId, isActionLoading),
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))),
                error: (err, stack) => const SizedBox(height: 80, child: Center(child: Text('Error loading status button'))),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => Center(child: Text('Error loading lobby details: $err')),
      ),
    );
  }

  /// Builds the top header showing sport category icon, title, and status badges.
  Widget _buildSportTitleRow(MatchModel match) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
          child: Icon(
            match.sport == 'Football' ? Icons.sports_soccer : Icons.sports,
            color: AppTheme.primaryColor,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                match.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.sport.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match.skillLevel.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a visual info grid displaying schedule and venue location parameters.
  Widget _buildInfoGrid(BuildContext context, MatchModel match) {
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(match.dateTime);
    final formattedTime = DateFormat('h:mm a').format(match.dateTime);

    return Column(
      children: [
        // Schedule detail
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
          ),
          title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('Starts at $formattedTime', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
        ),
        const Divider(height: 12),
        // Location address
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_outlined, color: AppTheme.secondaryColor),
          ),
          title: Text(match.venue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text('GPS: ${match.latitude.toStringAsFixed(4)}, ${match.longitude.toStringAsFixed(4)}', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
        ),
      ],
    );
  }

  /// Displays the match Host / Organizer's reliability bio details.
  Widget _buildOrganizerCard(BuildContext context, AsyncValue<UserModel?> organizerAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HOST & ORGANIZER',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.0),
        ),
        const SizedBox(height: 10),
        organizerAsync.when(
          data: (user) {
            if (user == null) {
              return const Text('Organizer profile details unavailable.', style: TextStyle(color: Colors.grey));
            }

            final reliability = user.reliabilityScore;
            Color scoreColor = AppTheme.primaryColor;
            if (reliability < 60) {
              scoreColor = AppTheme.errorColor;
            } else if (reliability < 80) {
              scoreColor = AppTheme.secondaryColor;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'O',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Skill: ${user.skillLevel} • Favorite Sport: ${user.favoriteSport}',
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Reliability indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${reliability.toInt()}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: scoreColor,
                        ),
                      ),
                      const Text(
                        'RELIABILITY',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: LinearProgressIndicator(color: AppTheme.primaryColor)),
          error: (err, stack) => const Text('Error loading host bio'),
        ),
      ],
    );
  }

  /// Builds the Team Skill Balancing engine panel.
  Widget _buildTeamBalancingWidget(BuildContext context, MatchModel match, List<ParticipantModel> participants) {
    if (participants.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance_rounded, color: AppTheme.secondaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'TEAM BALANCE INDICATOR',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Live calculation engine logic
          Consumer(
            builder: (context, ref, child) {
              double totalSkillPoints = 0.0;
              int activeCount = 0;

              for (final p in participants) {
                final profileAsync = ref.watch(userProfileProvider(p.userId));
                profileAsync.whenData((profile) {
                  if (profile != null) {
                    totalSkillPoints += AppConstants.skillLevelToInt(profile.skillLevel);
                    activeCount++;
                  }
                });
              }

              // Set safe defaults if background profile streams are still fetching
              if (activeCount == 0) {
                activeCount = 1;
                totalSkillPoints = AppConstants.skillLevelToInt(match.skillLevel).toDouble();
              }

              final double avgSkillScore = totalSkillPoints / activeCount;
              
              // Set dynamic text boundaries
              String avgSkillText = AppConstants.skillBeginner;
              Color skillColor = AppTheme.primaryColor;
              if (avgSkillScore > 2.3) {
                avgSkillText = AppConstants.skillAdvanced;
                skillColor = AppTheme.errorColor;
              } else if (avgSkillScore >= 1.7) {
                avgSkillText = AppConstants.skillIntermediate;
                skillColor = AppTheme.secondaryColor;
              }

              // Determine slot recommendation rules if balanced mode is enabled
              String recommendation = 'Suggested requirement: Any skill level.';
              if (match.balancedMode) {
                if (avgSkillScore > 2.3) {
                  recommendation = 'Suggesting: BEGINNER player to cool down/balance average team rating.';
                } else if (avgSkillScore < 1.7) {
                  recommendation = 'Suggesting: ADVANCED player to strengthen average team rating.';
                } else {
                  recommendation = 'Suggesting: INTERMEDIATE player to maintain balanced team rating.';
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Average Joined Player Level:',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                      ),
                      Text(
                        avgSkillText.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: skillColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Skill Rating slider bar preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: avgSkillScore / 3, // out of 3 maximum skill level score
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(skillColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Recommend slots message if balanced mode enabled
                  Row(
                    children: [
                      Icon(
                        match.balancedMode ? Icons.auto_awesome : Icons.info_outline_rounded,
                        size: 14,
                        color: match.balancedMode ? AppTheme.primaryColor : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.balancedMode 
                              ? recommendation 
                              : 'Balanced Mode disabled by host. Suggestion disabled.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: match.balancedMode ? FontWeight.bold : FontWeight.normal,
                            color: match.balancedMode ? Colors.white : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Lists all players registered for this match.
  Widget _buildParticipantsFeed(BuildContext context, AsyncValue<List<ParticipantModel>> participantsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline_rounded, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'PLAYERS SIGNED UP',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        participantsAsync.when(
          data: (parts) {
            if (parts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No players signed up yet.', style: TextStyle(color: Colors.grey)),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parts.length,
              itemBuilder: (context, index) {
                final participant = parts[index];
                return Consumer(
                  builder: (context, ref, child) {
                    final profileAsync = ref.watch(userProfileProvider(participant.userId));
                    return profileAsync.when(
                      data: (user) {
                        if (user == null) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.02)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.secondaryColor.withOpacity(0.1),
                                child: Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'P',
                                  style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.skillLevel.toUpperCase(),
                                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox(height: 48, child: Center(child: LinearProgressIndicator(color: AppTheme.primaryColor))),
                      error: (err, stack) => const SizedBox.shrink(),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          error: (err, stack) => const Text('Error loading participants'),
        ),
      ],
    );
  }

  /// Sticky action footer for atomic Join, Leave, or Organizer limitations.
  Widget _buildActionFooter(
    BuildContext context, 
    WidgetRef ref, 
    MatchModel match, 
    List<ParticipantModel> participants,
    String? currentUserId,
    bool isActionLoading,
  ) {
    if (currentUserId == null) return const SizedBox.shrink();

    // Check if current user has joined
    final bool isUserJoined = participants.any((p) => p.userId == currentUserId);
    final bool isOrganizer = match.organizerId == currentUserId;
    final bool isFull = match.currentPlayers >= match.maxPlayers;
    
    // Choose appropriate button configuration properties
    String buttonText = 'Join Match';
    Color buttonColor = AppTheme.primaryColor;
    Color textColors = Colors.black;
    VoidCallback? onPressed;

    if (isOrganizer) {
      buttonText = 'Host (Cannot Leave)';
      buttonColor = Colors.white.withOpacity(0.08);
      textColors = Colors.grey;
      onPressed = null; // Organizer cannot leave their own match via standard join button
    } else if (isUserJoined) {
      buttonText = 'Leave Match';
      buttonColor = AppTheme.errorColor;
      textColors = Colors.white;
      onPressed = isActionLoading 
          ? null 
          : () async {
              final success = await ref.read(matchControllerProvider.notifier).leaveMatchSlot(match.matchId, currentUserId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have successfully left the match.'),
                    backgroundColor: AppTheme.secondaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            };
    } else if (isFull) {
      buttonText = 'Match is Full';
      buttonColor = Colors.white.withOpacity(0.08);
      textColors = Colors.grey;
      onPressed = null;
    } else {
      onPressed = isActionLoading
          ? null
          : () async {
              final success = await ref.read(matchControllerProvider.notifier).joinMatchSlot(match.matchId, currentUserId);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You have successfully joined the match!'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            };
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColors,
          disabledBackgroundColor: buttonColor,
          disabledForegroundColor: textColors,
        ),
        child: isActionLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(buttonText),
      ),
    );
  }
}
