import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squadfill/core/theme/app_theme.dart';
import 'package:squadfill/data/models/match_model.dart';
import 'package:squadfill/data/models/participant_model.dart';
import 'package:squadfill/data/models/skill_feedback_model.dart';
import 'package:squadfill/presentation/providers/auth_providers.dart';
import 'package:squadfill/presentation/providers/feedback_providers.dart';
import 'package:squadfill/presentation/providers/match_providers.dart';
import 'package:squadfill/presentation/widgets/skill_chip_selector.dart';

/// Screen where users rate the skill levels of their teammates after a match.
class RateTeammatesScreen extends ConsumerStatefulWidget {
  final MatchModel match;

  const RateTeammatesScreen({super.key, required this.match});

  @override
  ConsumerState<RateTeammatesScreen> createState() => _RateTeammatesScreenState();
}

class _RateTeammatesScreenState extends ConsumerState<RateTeammatesScreen> {
  // Map to store selected ratings: userId -> skillLevel
  final Map<String, String> _ratings = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentSquadUserProvider);
    final participantsAsync = ref.watch(matchParticipantsStreamProvider(widget.match.matchId));
    final controllerState = ref.watch(feedbackControllerProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Rate Teammates'),
      ),
      body: participantsAsync.when(
        data: (participants) {
          // Exclude the current user from the rating list
          final teammates = participants.where((p) => p.userId != currentUser?.uid).toList();

          if (teammates.isEmpty) {
            return const Center(child: Text('No teammates found to rate.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'How did your teammates perform in ${widget.match.title}?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: teammates.length,
                  itemBuilder: (context, index) {
                    final teammate = teammates[index];
                    return _buildTeammateRatingCard(teammate);
                  },
                ),
              ),
              _buildSubmitButton(teammates, currentUser?.uid),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => Center(child: Text('Error loading teammates: $err')),
      ),
    );
  }

  Widget _buildTeammateRatingCard(ParticipantModel participant) {
    return Consumer(
      builder: (context, ref, child) {
        final profileAsync = ref.watch(userProfileProvider(participant.userId));
        
        return profileAsync.when(
          data: (user) {
            if (user == null) return const SizedBox.shrink();
            
            final currentRating = _ratings[user.uid] ?? 'Intermediate';

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: Text(user.name[0].toUpperCase()),
                        ),
                        const SizedBox(width: 16),
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SkillChipSelector(
                      selectedSkill: currentRating,
                      onSelected: (skill) {
                        setState(() {
                          _ratings[user.uid] = skill;
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox(height: 100, child: Center(child: LinearProgressIndicator())),
          error: (err, stack) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildSubmitButton(List<ParticipantModel> teammates, String? currentUserId) {
    final controller = ref.watch(feedbackControllerProvider);
    final isLoading = controller is AsyncLoading;

    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _submitAllFeedback(teammates, currentUserId),
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black))
            : const Text('Submit Ratings'),
      ),
    );
  }

  Future<void> _submitAllFeedback(List<ParticipantModel> teammates, String? currentUserId) async {
    if (currentUserId == null) return;

    bool allSuccess = true;
    for (final teammate in teammates) {
      final rating = _ratings[teammate.userId] ?? 'Intermediate';
      final feedback = SkillFeedbackModel(
        feedbackId: '',
        fromUserId: currentUserId,
        toUserId: teammate.userId,
        matchId: widget.match.matchId,
        ratingGiven: rating,
        createdAt: DateTime.now(),
      );

      final success = await ref.read(feedbackControllerProvider.notifier).submitFeedback(feedback);
      if (!success) allSuccess = false;
    }

    if (mounted) {
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted! Ratings help balance future matches.'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Some feedback failed to submit. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
